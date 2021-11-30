RSpec.describe SteelWheel::Command do
  DATA = { 'base/1' => true }.freeze

  vars do
    command_class do
      Class.new(SteelWheel::Command) do
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
    command { command_class.new(id: id) }
  end

  it { expect(command_class).to respond_to(:memoize) }
  it { expect(command).to respond_to(:data) }
  it { expect(command).to respond_to(:random_object_id) }

  describe '.name' do
    it 'returns SteelWheel::Command' do
      expect(command_class.name).to eq 'SteelWheel::Command'
    end
  end

  describe '.http_status' do
    vars do
      command { command_class.new(id: 2) }
    end

    it 'returns first key in errors if there are errors' do
      command.invalid?
      expect(command.http_status).to eq :base
    end

    it 'returns nil if there are no errors' do
      command = command_class.new(id: 'base/1')
      command.invalid?
      expect(command.http_status).to eq nil
    end
  end

  it 'is subclass of ActiveModel::Validations' do
    expect(SteelWheel::Command.ancestors).to include(ActiveModel::Validations)
  end

  it 'memoize methods' do
    old_id = command.random_object_id
    expect(command.random_object_id).to eq old_id
  end

  context 'when validation passes' do
    it 'valid? returns true' do
      expect(command).to be_valid
    end
  end

  context 'when validation does not pass' do
    vars do
      command { command_class.new(id: 2) }
      messages { ['Couldn\'t find DATA with id=2'] }
    end

    it 'invalid? returns true' do
      expect(command).to be_invalid
    end

    it 'has errors messages' do
      command.invalid?
      expect(command.errors.to_a).to eq messages
    end
  end
end
