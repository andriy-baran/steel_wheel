require 'spec_helper'

RSpec.describe SteelWheel::Operation do
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
        text: { error: 'error', message: 'Id can\'t be blank' }.to_json,
        content_type: 'application/json',
        status: :bad_request
      }
    end
    invalid_context_result do
      {
        text: { error: 'error', message: 'Context error' }.to_json,
        content_type: 'application/json',
        status: :forbidden
      }
    end
    ok_result do
      {
        text: {}.to_json,
        content_type: 'application/json',
        status: :ok
      }
    end
    operation_class do
      Class.new(SteelWheel::Operation) do
        include SteelWheel::Flows::ApiJson
        result_defaults :json, content_type: 'application/json', status: :ok, text: '{}'
        def on_params_failure
          result.text = self.class.errors_format.call(given.errors.full_messages.join("\n")).to_json
          result.status = :bad_request
        end
        def on_context_failure
          errors = given.errors.full_messages_for(given.error_key).join("\n")
          result.text = self.class.errors_format.call(errors).to_json
          result.status = given.error_key
        end
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
  it { expect(operation_class).to respond_to(:context_controller_class) }
  it { expect(operation_class).to respond_to(:action_controller_class) }

  describe '.params' do
    context 'when class provided' do
      it 'saves it instance variable' do
        params_class = Class.new(SteelWheel::Params)
        operation_class.params(params_class)
        expect(operation_class.params_input_class).to eq params_class
      end
    end

    context 'when class provided, but not a subclass of SteelWheel::Params' do
      it 'raises ArgumentError' do
        params_class = Class.new
        expect do
          operation_class.params(params_class)
        end.to raise_error(ArgumentError, 'must be a subclass of SteelWheel::Params')
      end
    end

    context 'when class provided and block provided' do
      it 'dynamically creates a subclass of SteelWheel::Params and evaluates code block in it' do
        operation_class.params do
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
        operation_class.context(context_class)
        expect(operation_class.context_controller_class).to eq context_class
      end
    end

    context 'when class provided, but not a subclass of SteelWheel::Context' do
      it 'raises ArgumentError' do
        context_class = Class.new
        expect do
          operation_class.context(context_class)
        end.to raise_error(ArgumentError, 'must be a subclass of SteelWheel::Context')
      end
    end

    context 'when class provided and block provided' do
      it 'dynamically creates a subclass of SteelWheel::Context and evaluates code block in it' do
        operation_class.context do
          def quantity
            1
          end
        end
        expect(operation_class.context_controller_class.superclass).to eq SteelWheel::Context
        expect(operation_class.context_controller_class.new.quantity).to eq 1
      end
    end
  end

  describe '.action' do
    context 'when class provided' do
      it 'saves it instance variable' do
        action_class = Class.new(SteelWheel::Action)
        operation_class.action(action_class)
        expect(operation_class.action_controller_class).to eq action_class
      end
    end

    context 'when class provided, but not a subclass of SteelWheel::Action' do
      it 'raises ArgumentError' do
        action_class = Class.new
        expect do
          operation_class.action(action_class)
        end.to raise_error(ArgumentError, 'must be a subclass of SteelWheel::Action')
      end
    end

    context 'when class provided and block provided' do
      it 'dynamically creates a subclass of SteelWheel::Action and evaluates code block in it' do
        operation_class.action do
          def quantity
            1
          end
        end
        expect(operation_class.action_controller_class.superclass).to eq SteelWheel::Action
        expect(operation_class.action_controller_class.new.quantity).to eq 1
      end
    end
  end

  context 'when params, context, action provided' do
    before do
      operation_class.params(params_class)
      operation_class.context(context_class)
      operation_class.action(action_class)
    end

    it 'returns an instance of self' do
      expect(operation_class.prepare).to be_an_instance_of operation_class
    end

    context 'when params object is invalid' do
      it 'returns an instance of NoOperation' do
        operation = operation_class.accept({}).prepare
        expect(operation).to be_a SteelWheel::Operation
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
        operation = operation_class.accept({id: 1}).prepare
        expect(operation).to be_a SteelWheel::Operation
      end
    end
  end

  describe '.error_format' do
    before(:each) do
      operation_class.params(params_class)
      operation_class.context(context_class)
      operation_class.action(action_class)
      operation_class.errors_format do |error_message|
        { errors: error_message }
      end
    end

    context 'when base class' do
      it 'has customized errors' do
        op = operation_class.accept({id: nil}).prepare
        op.call
        expect(op.result.to_h[:text]).to eq({ errors: "Id can't be blank" }.to_json)
      end
    end

    context 'when child class' do
      it 'has customized errors' do
        child_class = Class.new(operation_class)
        op = child_class.accept({id: nil}).prepare
        expect(op.result.to_h[:text]).to eq({ errors: "Id can't be blank" }.to_json)
      end
    end
  end

  describe '#result' do
    before do
      operation_class.params(params_class)
      operation_class.context(context_class)
      operation_class.action(action_class)
    end

    context 'when params object is invalid' do
      it 'returns correct result' do
        operation = operation_class.accept({}).prepare
        expect(operation.result.to_h).to eq invalid_params_result
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
        operation = operation_class.accept({id: 1}).prepare
        expect(operation.result.to_h).to eq invalid_context_result
      end
    end

    context 'when everything is ok' do
      it 'returns correct result' do
        operation = operation_class.accept({id: 1}).prepare
        expect(operation.result.to_h).to eq ok_result
      end
    end

    context 'when context is extended' do
      it 'returns correct result' do
        context_class.class_eval{ attr_accessor :new_value }
        operation_class.context(context_class)
        operation = operation_class.accept({id: 1}).prepare do |ctx|
          ctx.new_value = 15
        end
        expect(operation.given.new_value).to eq 15
      end
    end
  end
end
