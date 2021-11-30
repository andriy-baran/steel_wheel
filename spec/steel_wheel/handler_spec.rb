require 'spec_helper'

RSpec.describe SteelWheel::Handler do
  vars do
    params_class do
      Class.new(SteelWheel::Params) do
        attribute :id, integer

        validates :id, presence: { message: "can't be blank" }
      end
    end
    command_class do
      Class.new(SteelWheel::Command) do
        def call
          true
        end
        def upcased_title
          'ACTION'
        end
      end
    end
    invalid_params_result do
      {
        errors: ['Id can\'t be blank'],
        status: :bad_request
      }
    end
    invalid_command_result do
      {
        errors: ['Command error'],
        status: :forbidden
      }
    end
    ok_result do
      {
        errors: [],
        status: :ok
      }
    end
    operation_class do
      Class.new(SteelWheel::Handler) do
        class << self
          attr_accessor :init_proc
        end
        response_output do
          def to_h; {status: status, errors: errors.full_messages}; end
        end
        def call
          'Operation result'
        end
      end
    end
    title { 'new command' }
    command { OpenStruct.new(title: title) }
  end

  it { expect(operation_class).to respond_to(:params_input_class) }
  it { expect(operation_class).to respond_to(:command_stage_class) }

  describe '.params' do
    context 'when class provided' do
      it 'saves it instance variable' do
        params_class = Class.new(SteelWheel::Params)
        operation_class.input(:params, base_class: params_class)
        expect(operation_class.params_input_class).to eq params_class
      end
    end

    context 'when class provided, but not a subclass of SteelWheel::Params' do
      it 'raises ArgumentError' do
        params_class = Class.new
        expect do
          operation_class.params_input_class = params_class
        end.to raise_error(ArgumentError, 'must be a subclass of SteelWheel::Params')
      end
    end

    context 'when class provided and block provided' do
      it 'dynamically creates a subclass of SteelWheel::Params and evaluates code block in it' do
        operation_class.send(:params_input) do
          attribute :quantity, integer.default(1)
        end
        expect(operation_class.params_input_class.superclass).to eq SteelWheel::Params
        expect(operation_class.params_input_class.new.quantity).to eq 1
      end
    end
  end

  describe '.command' do
    context 'when class provided' do
      it 'saves it instance variable' do
        command_class = Class.new(SteelWheel::Command)
        operation_class.stage(:command, base_class: command_class)
        expect(operation_class.command_stage_class).to eq command_class
      end
    end

    context 'when class provided, but not a subclass of SteelWheel::Command' do
      it 'raises ArgumentError' do
        command_class = Class.new
        expect do
          operation_class.command_stage_class = (command_class)
        end.to raise_error(ArgumentError, 'must be a subclass of SteelWheel::Command')
      end
    end

    context 'when class provided and block provided' do
      it 'dynamically creates a subclass of SteelWheel::Command and evaluates code block in it' do
        operation_class.send(:command_stage) do
          def quantity
            1
          end
        end
        expect(operation_class.command_stage_class.superclass).to eq SteelWheel::Command
        expect(operation_class.command_stage_class.new.quantity).to eq 1
      end
    end
  end

  context 'when params, context, command provided' do
    before do
      operation_class.params_input_class = params_class
      operation_class.command_stage_class = command_class
    end

    it 'returns an instance of self' do
      expect(operation_class.handle(input: {})).to be_an_instance_of operation_class
    end

    context 'when params object is invalid' do
      it 'returns an instance of NoOperation' do
        operation = operation_class.handle(input: {})
        expect(operation).to be_a SteelWheel::Handler
      end
    end

    context 'when command object is invalid' do
      vars do
        command_class do
          Class.new(SteelWheel::Command) do
            def record; end
            validate { errors.add(:base, 'Command error') if record.nil? }
          end
        end
      end

      it 'returns an instance of NoOperation' do
        operation = operation_class.handle(input: {id: 1})
        expect(operation).to be_a SteelWheel::Handler
      end
    end
  end

  describe '#result' do
    before do
      operation_class.params_input_class = params_class
      operation_class.command_stage_class = command_class
    end

    context 'when params object is invalid' do
      it 'returns correct result' do
        operation = operation_class.handle(input: {})
        expect(operation.output.to_h).to eq invalid_params_result
      end
    end

    context 'when command object is invalid' do
      vars do
        command_class do
          Class.new(SteelWheel::Command) do
            def record; end
            validate { errors.add(:forbidden, 'Command error') if record.nil? }
          end
        end
      end

      it 'returns correct result' do
        operation = operation_class.handle(input: {id: 1})
        expect(operation.output.to_h).to eq invalid_command_result
      end
    end

    context 'when everything is ok' do
      it 'returns correct result' do
        operation = operation_class.handle(input: {id: 1})
        expect(operation.output.to_h).to eq ok_result
      end
    end

    context 'when context is extended' do
      it 'returns correct result' do
        query_class = Class.new(SteelWheel::Query) { attr_accessor :new_value }
        operation_class.query_stage_class = query_class
        result = operation_class.handle(input: {id: 1}) do |ctx|
                   ctx.new_value = 15
                 end
        expect(result.output.new_value).to eq 15
      end
    end
  end
end
