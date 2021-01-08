require 'spec_helper'

RSpec.describe SteelWheel::Rail do
  vars do
    params_class do
      Class.new(SteelWheel::Params) do
        attribute :id, integer

        validates :id, presence: { message: "can't be blank" }
      end
    end
    context_class do
      Class.new(SteelWheel::Context) do
        def call
          true
        end
      end
    end
    action_class do
      Class.new(SteelWheel::Action) do
        def upcased_title
          'ACTION'
        end
      end
    end
    invalid_params_result do
      {
        json: { error: 'error', message: 'Id can\'t be blank' }.to_json,
        status: :bad_request
      }
    end
    invalid_context_result do
      {
        json: { error: 'error', message: 'Context error' }.to_json,
        status: :forbidden
      }
    end
    ok_result do
      {
        json: {}.to_json,
        status: :ok
      }
    end
    operation_class do
      Class.new(SteelWheel::Rail) do
        include SteelWheel::Flows::ApiJson
        class << self
          attr_accessor :init_proc
        end
        self.init_proc = ->(klass) { klass.new({status: :ok, json: '{}'}) }
        json_output(init: init_proc) {}
        # def on_params_input_failure
        #   result.text = self.class.errors_format.call(given.errors.full_messages.join("\n")).to_json
        #   result.status = :bad_request
        # end
        # def on_context_stage_failure
        #   errors = given.errors.full_messages_for(given.error_key).join("\n")
        #   result.text = self.class.errors_format.call(errors).to_json
        #   result.status = given.error_key
        # end
        def call
          'Operation result'
        end
      end
    end
    title { 'new action' }
    context_object { OpenStruct.new(title: title) }
    action { action_class.new(context_object) }
  end

  it { expect(operation_class).to respond_to(:params_input_class) }
  it { expect(operation_class).to respond_to(:context_stage_class) }
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

  describe '.context' do
    context 'when class provided' do
      it 'saves it instance variable' do
        context_class = Class.new(SteelWheel::Context)
        operation_class.stage(:context, base_class: context_class)
        expect(operation_class.context_stage_class).to eq context_class
      end
    end

    context 'when class provided, but not a subclass of SteelWheel::Context' do
      it 'raises ArgumentError' do
        context_class = Class.new
        expect do
          operation_class.context_stage_class = context_class
        end.to raise_error(ArgumentError, 'must be a subclass of SteelWheel::Context')
      end
    end

    context 'when class provided and block provided' do
      it 'dynamically creates a subclass of SteelWheel::Context and evaluates code block in it' do
        operation_class.send(:context_stage) do
          def quantity
            1
          end
        end
        expect(operation_class.context_stage_class.superclass).to eq SteelWheel::Context
        expect(operation_class.context_stage_class.new.quantity).to eq 1
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
      operation_class.context_stage_class = context_class
      operation_class.action_stage_class = action_class
    end

    it 'returns an instance of self' do
      expect(operation_class.accept({}).call).to be_an_instance_of operation_class
    end

    context 'when params object is invalid' do
      it 'returns an instance of NoOperation' do
        operation = operation_class.accept({}).call
        expect(operation).to be_a SteelWheel::Rail
      end
    end

    context 'when context object is invalid' do
      vars do
        context_class do
          Class.new(SteelWheel::Context) do
            def record; end
            validate { errors.add(:base, 'Context error') if record.nil? }
          end
        end
      end

      it 'returns an instance of NoOperation' do
        operation = operation_class.accept({id: 1}).call
        expect(operation).to be_a SteelWheel::Rail
      end
    end
  end

  describe '.error_format' do
    before(:each) do
      operation_class.params_input_class = params_class
      operation_class.context_stage_class = context_class
      operation_class.action_stage_class = action_class
      operation_class.errors_format do |error_message|
        { errors: error_message }
      end
    end

    context 'when base class' do
      it 'has customized errors' do
        op = operation_class.accept({id: nil}).call
        expect(op.output.to_h[:json]).to eq({ errors: "Id can't be blank" }.to_json)
      end
    end

    context 'when child class' do
      it 'has customized errors' do
        child_class = Class.new(operation_class)
        op = child_class.accept({id: nil}).call
        expect(op.output.to_h[:json]).to eq({ errors: "Id can't be blank" }.to_json)
      end
    end
  end

  describe '#result' do
    before do
      operation_class.params_input_class = params_class
      operation_class.context_stage_class = context_class
      operation_class.action_stage_class = action_class
    end

    context 'when params object is invalid' do
      it 'returns correct result' do
        operation = operation_class.accept({}).call
        expect(operation.output.to_h).to eq invalid_params_result
      end
    end

    context 'when context object is invalid' do
      vars do
        context_class do
          Class.new(SteelWheel::Context) do
            def record; end
            validate { errors.add(:forbidden, 'Context error') if record.nil? }
          end
        end
      end

      it 'returns correct result' do
        operation = operation_class.accept({id: 1}).call
        expect(operation.output.to_h).to eq invalid_context_result
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
        context_class.class_eval{ attr_accessor :new_value }
        operation_class.context_stage_class = context_class
        operation = operation_class.accept({id: 1}).call do |ctx|
          ctx.new_value = 15
        end
        expect(operation.given.new_value).to eq 15
      end
    end
  end
end
