RSpec.describe SteelWheel::Action do
  DATA = { 'base/1' => true }.freeze

  vars do
    action_class do
      Class.new(SteelWheel::Action) do
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
    action { action_class.new(id: id) }
  end

  it { expect(action_class).to respond_to(:memoize) }
  it { expect(action).to respond_to(:data) }
  it { expect(action).to respond_to(:random_object_id) }

  describe '.name' do
    it 'returns SteelWheel::Action' do
      expect(action_class.name).to eq 'SteelWheel::Action'
    end
  end

  describe '.http_status' do
    vars do
      action { action_class.new(id: 2) }
    end

    it 'returns first key in errors if there are errors' do
      action.invalid?
      expect(action.http_status).to eq :base
    end

    it 'returns nil if there are no errors' do
      action = action_class.new(id: 'base/1')
      action.invalid?
      expect(action.http_status).to eq nil
    end
  end

  it 'is subclass of ActiveModel::Validations' do
    expect(SteelWheel::Action.ancestors).to include(ActiveModel::Validations)
  end

  it 'memoize methods' do
    old_id = action.random_object_id
    expect(action.random_object_id).to eq old_id
  end

  context 'error messages' do
    vars do
      action_class do
        Class.new(SteelWheel::Action) do
          validate { errors.add(:forbidden, 'Error Message') }
        end
      end
    end

    it 'skips :not_found, :forbidden, :unprocessable_entity in full error messages' do
      action = action_class.new.tap(&:valid?)
      expect(action.errors.to_a).to eq ['Error Message']
      expect(action.http_status).to eq :forbidden
    end
  end

  context 'when validation passes' do
    it 'valid? returns true' do
      expect(action).to be_valid
    end
  end

  context 'when validation does not pass' do
    vars do
      action { action_class.new(id: 2) }
      messages { ['Couldn\'t find DATA with id=2'] }
    end

    it 'invalid? returns true' do
      expect(action).to be_invalid
    end

    it 'has errors messages' do
      action.invalid?
      expect(action.errors.to_a).to eq messages
    end
  end
end
