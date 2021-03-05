require 'spec_helper'

RSpec.describe SteelWheel::Handler do
  vars do
    params_class do
      Class.new(SteelWheel::Params) do
        attribute :id, integer

        validates :id, presence: { message: "can't be blank" }
      end
    end
    action_class do
      Class.new(SteelWheel::Action) do
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
    invalid_action_result do
      {
        errors: ['Action error'],
        status: :forbidden
      }
    end
    ok_result do
      {
        errors: nil,
        status: :ok
      }
    end
    operation_class do
      Class.new(SteelWheel::Handler) do
        class << self
          attr_accessor :init_proc
        end
        response_output do
          def to_h; {status: status, errors: errors}; end
        end
        def call
          'Operation result'
        end
      end
    end
    title { 'new action' }
    action { OpenStruct.new(title: title) }
  end

  it { expect(operation_class).to respond_to(:params_input_class) }
  it { expect(operation_class).to respond_to(:action_stage_class) }

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

  describe '.action' do
    context 'when class provided' do
      it 'saves it instance variable' do
        action_class = Class.new(SteelWheel::Action)
        operation_class.stage(:action, base_class: action_class)
        expect(operation_class.action_stage_class).to eq action_class
      end
    end

    context 'when class provided, but not a subclass of SteelWheel::Action' do
      it 'raises ArgumentError' do
        action_class = Class.new
        expect do
          operation_class.action_stage_class = (action_class)
        end.to raise_error(ArgumentError, 'must be a subclass of SteelWheel::Action')
      end
    end

    context 'when class provided and block provided' do
      it 'dynamically creates a subclass of SteelWheel::Action and evaluates code block in it' do
        operation_class.send(:action_stage) do
          def quantity
            1
          end
        end
        expect(operation_class.action_stage_class.superclass).to eq SteelWheel::Action
        expect(operation_class.action_stage_class.new.quantity).to eq 1
      end
    end
  end

  context 'when params, context, action provided' do
    before do
      operation_class.params_input_class = params_class
      operation_class.action_stage_class = action_class
    end

    it 'returns an instance of self' do
      expect(operation_class.accept({}).call).to be_an_instance_of operation_class
    end

    context 'when params object is invalid' do
      it 'returns an instance of NoOperation' do
        operation = operation_class.accept({}).call
        expect(operation).to be_a SteelWheel::Handler
      end
    end

    context 'when action object is invalid' do
      vars do
        action_class do
          Class.new(SteelWheel::Action) do
            def record; end
            validate { errors.add(:base, 'Action error') if record.nil? }
          end
        end
      end

      it 'returns an instance of NoOperation' do
        operation = operation_class.accept({id: 1}).call
        expect(operation).to be_a SteelWheel::Handler
      end
    end
  end

  describe '#result' do
    before do
      operation_class.params_input_class = params_class
      operation_class.action_stage_class = action_class
    end

    context 'when params object is invalid' do
      it 'returns correct result' do
        operation = operation_class.accept({}).call
        expect(operation.output.to_h).to eq invalid_params_result
      end
    end

    context 'when action object is invalid' do
      vars do
        action_class do
          Class.new(SteelWheel::Action) do
            def record; end
            validate { errors.add(:forbidden, 'Action error') if record.nil? }
          end
        end
      end

      it 'returns correct result' do
        operation = operation_class.accept({id: 1}).call
        expect(operation.output.to_h).to eq invalid_action_result
      end
    end

    context 'when everything is ok' do
      it 'returns correct result' do
        operation = operation_class.accept({id: 1}).call
        expect(operation.output.to_h).to eq ok_result
      end
    end

    context 'when context is extended' do
      it 'returns correct result' do
        action_class.class_eval{ attr_accessor :new_value }
        operation_class.action_stage_class = action_class
        operation = operation_class.accept({id: 1}) do |ctx|
                      ctx.new_value = 15
                    end
        handler = operation.call
        expect(handler.given.new_value).to eq 15
      end
    end
  end
end
