RSpec.describe SteelWheel::Context do
  DATA = { 'base/1' => true }.freeze

  vars do
    context_class do
      Class.new(SteelWheel::Context) do
        def initialize(opts)
          opts.each do |(key, value)|
            self.class.class_eval{attr_accessor key}
            instance_variable_set(:"@#{key}", value)
          end
        end

        def data
          DATA[id]
        end

        memoize def random_object_id
          OpenStruct.new.object_id
        end

        validate do
          errors.add(:base, "Couldn't find DATA with id=#{id}") if data.nil?
        end
      end
    end
    id { 'base/1' }
    context { context_class.new(id: id) }
  end

  it { expect(context_class).to respond_to(:memoize) }
  it { expect(context).to respond_to(:data) }
  it { expect(context).to respond_to(:random_object_id) }

  describe '.name' do
    it 'returns SteelWheel::Context' do
      expect(context_class.name).to eq 'SteelWheel::Context'
    end
  end

  describe '.error_key' do
    vars do
      context { context_class.new(id: 2) }
    end

    it 'returns first key in errors if there are errors' do
      context.invalid?
      expect(context.error_key).to eq :base
    end

    it 'returns nil if there are no errors' do
      context = context_class.new(id: 'base/1')
      context.invalid?
      expect(context.error_key).to eq nil
    end
  end

  it 'is subclass of ActiveModel::Validations' do
    expect(SteelWheel::Context.ancestors).to include(ActiveModel::Validations)
  end

  it 'memoize methods' do
    old_id = context.random_object_id
    expect(context.random_object_id).to eq old_id
  end

  context 'error messages' do
    vars do
      context_class do
        Class.new(SteelWheel::Context) do
          validate { errors.add(:forbidden, 'Error Message') }
        end
      end
    end

    it 'skips :not_found, :forbidden, :unprocessable_entity in full error messages' do
      ctx = context_class.new.tap(&:valid?)
      expect(ctx.errors.to_a).to eq ['Error Message']
      expect(ctx.error_key).to eq :forbidden
    end
  end

  context 'when validation passes' do
    it 'valid? returns true' do
      expect(context).to be_valid
    end
  end

  context 'when validation does not pass' do
    vars do
      context { context_class.new(id: 2) }
      messages { ['Couldn\'t find DATA with id=2'] }
    end

    it 'invalid? returns true' do
      expect(context).to be_invalid
    end

    it 'has errors messages' do
      context.invalid?
      expect(context.errors.to_a).to eq messages
    end
  end
end
