# frozen_string_literal: true

require 'spec_helper'

class ChildParams < SteelWheel::Params
  integer :id, presence: { message: "can't be blank" }
end

class Entity
  include ActiveModel::Validations
  attr_accessor :id

  def initialize(id = nil)
    @id = id
  end

  validates :id, presence: { message: "can't be blank" }
end

RSpec.describe SteelWheel::Handler do
  vars do
    invalid_params_result do
      {
        errors: ["Id can't be blank", "Quantity can't be blank", "Quantity is not a number"],
        status: :bad_request
      }
    end

    invalid_query_result do
      {
        errors: ['Query error'],
        status: :not_found
      }
    end

    invalid_command_result do
      {
        errors: ['Command error'],
        status: :forbidden
      }
    end

    invalid_entity_result do
      {
        errors: ['Please provide valid entity id'],
        status: :unprocessable_entity
      }
    end

    ok_result do
      {
        errors: [],
        status: :ok
      }
    end

    handler_class do
      Class.new(SteelWheel::Handler) do
        attr_accessor :new_value

        url_params ChildParams

        def to_h
          { status: http_status, errors: errors.full_messages }
        end

        def call
        end

        def on_validation_success
          call
        end
      end
    end
    title { 'new command' }
    command { OpenStruct.new(title: title) }
  end

  describe '#result' do
    context 'when params object is invalid' do
      vars do
        operation_class do
          Class.new(SteelWheel::Handler) do
            url_params do
              integer :id, presence: { message: "can't be blank" }
              integer :quantity, presence: true, numericality: { greater_than: 0 }
            end

            def entity
              Entity.new
            end

            verify :entity,
                    valid: {
                      base: true,
                      message: {
                        id: -> (o, d) { "Please provide valid entity id" },
                        base: true
                      }
                    }

            def to_h
              { status: http_status, errors: errors.full_messages }
            end

            def call
              to_h
            end
          end
        end
      end

      it 'returns invalid params error' do
        operation = operation_class.handle
        expect(operation.to_h).to eq invalid_params_result
      end

      it 'returns invalid entity error' do
        operation = operation_class.handle({ id: 4, quantity: 1 })
        expect(operation.to_h).to eq invalid_entity_result
      end
    end

    context 'When all objects are invalid' do
      vars do
        operation_class do
          Class.new(handler_class) do
            url_params do
              validate { errors.add(:base, :bad_request, message: 'Params error') }
            end
            validate { errors.add(:base, :not_found, message: 'Query error') }
            validate { errors.add(:base, :forbidden, message: 'Command error') }
          end
        end
      end

      it 'returns correct result' do
        operation = operation_class.handle({ id: 1, quantity: 1 })
        expect(operation.to_h).to eq({ status: :bad_request, errors: ['Params error']  })
      end
    end

    context 'when everything is ok' do
      it 'returns correct result' do
        operation = handler_class.handle({ id: 1 })
        expect(operation.to_h).to eq ok_result
      end
    end

    context 'when context is extended' do
      it 'returns correct result' do
        result = handler_class.handle({ id: 1 }) do |i|
          i.new_value = 15
        end
        expect(result.new_value).to eq 15
      end
    end

    context 'when callbacks are provided' do
      it 'returns correct result' do
        result = handler_class.handle({ id: 1 }) do |i|
          i.new_value = 15
        end
        expect(result.new_value).to eq 15
      end
    end
  end

  describe 'form functionality' do
    context 'when form_attributes is not implemented' do
      vars do
        invalid_form_handler_class do
          Class.new(SteelWheel::Handler) do
            form do
              element :name do
                input type: :text
                output type: :string
              end
            end

            def call
              { result: 'success' }
            end
          end
        end
      end

      it 'raises FormAttributesNotImplementedError' do
        handler = invalid_form_handler_class.new({ name: 'John' })
        expect { handler.form }.to raise_error(SteelWheel::FormAttributesNotImplementedError)
      end
    end
  end

  describe 'callback functionality' do
    context 'when success callback is defined' do
      vars do
        callback_handler_class do
          Class.new(SteelWheel::Handler) do
            url_params do
              integer :id, presence: { message: "can't be blank" }
            end


            def call
              { result: 'success' }
            end
          end
        end
      end

      it 'executes success callback when operation succeeds' do
        callback_executed = false
        callback_value = nil

        callback_handler_class.handle({ id: 1 }) do |handler|
          handler.success do |h|
            callback_executed = true
            callback_value = 'success_callback_executed'
          end
        end
        expect(callback_executed).to be true
        expect(callback_value).to eq 'success_callback_executed'
      end
    end

    context 'when failure callbacks are defined' do
      vars do
        failure_callback_handler_class do
          Class.new(SteelWheel::Handler) do
            url_params do
              integer :id, presence: { message: "can't be blank" }
            end

            validate do
              errors.add(:base, :not_found, message: 'Resource not found')
              self.http_status = :not_found
            end

            def call
              { result: 'failure' }
            end
          end
        end
      end

      it 'executes failure callback when operation fails' do
        callback_executed = false
        callback_status = nil

        failure_callback_handler_class.handle({ id: 1 }) do |handler|
          handler.failure :not_found do |h|
            callback_executed = true
            callback_status = :not_found
          end
        end
        expect(callback_executed).to be true
        expect(callback_status).to eq :not_found
      end
    end

    context 'when multiple failure callbacks are defined' do
      vars do
        multi_failure_callback_handler_class do
          Class.new(SteelWheel::Handler) do
            url_params do
              integer :id, presence: { message: "can't be blank" }
            end

            validate do
              errors.add(:base, :forbidden, message: 'Access denied')
              self.http_status = :forbidden
            end

            def call
              { result: 'failure' }
            end
          end
        end
      end

      it 'executes callback for multiple status codes' do
        callback_executed = false
        callback_status = nil

        multi_failure_callback_handler_class.handle({ id: 1 }) do |handler|
          handler.failure :not_found, :forbidden do |h|
            callback_executed = true
            callback_status = h.http_status
          end
        end
        expect(callback_executed).to be true
        expect(callback_status).to eq :forbidden
      end
    end

    context 'when no callbacks are defined' do
      vars do
        no_callback_handler_class do
          Class.new(SteelWheel::Handler) do
            url_params do
              integer :id, presence: { message: "can't be blank" }
            end

            def call
              { result: 'success' }
            end
          end
        end
      end

      it 'executes without errors when no callbacks are defined' do
        result = no_callback_handler_class.handle({ id: 1 })
        expect(result).to be_a(SteelWheel::Handler)
        expect(result.errors.empty?).to be true
      end
    end
  end

  describe 'forms and callbacks integration' do
    context 'when form and callbacks work together with scoped forms' do
      User = Struct.new(:name, :email, keyword_init: true) do
        def self.model_name
          OpenStruct.new(param_key: :user)
        end
      end
      vars do
        scoped_form_callback_handler_class do
          Class.new(SteelWheel::Handler) do
            attr_accessor :callback_executed, :form_data

            url_params do
              integer :id, presence: { message: "can't be blank" }
            end

            form do
              resource_model User

              element :name do
                input type: :text
                output type: :string, presence: { message: "can't be blank" }
              end

              element :email do
                input type: :email
                output type: :string, presence: { message: "can't be blank" }
              end
            end

            def model
              User.new(form_params.to_h)
            end

            def form_attributes
              { model: model }
            end

            def call
              { result: 'success', form_data: form_params.to_h }
            end
          end
        end
      end

      it 'handles scoped form with success callback' do
        owner = double('owner', request: double('request', request_method: 'POST', path: '/users/1'))
        callback_executed = false

        result = scoped_form_callback_handler_class.handle({ id: 1, user: { name: 'John' } }) do |handler|
          handler.owner = owner
          handler.failure :unprocessable_entity do |h|
            callback_executed = true
          end
        end
        expect(callback_executed).to be true
        expect(result.class.form_definition.scope).to eq :user
        expect(result.form_input).to eq({ name: 'John' })
        expect(result.form).to be_a(ActionForm::Rails::Base)
      end
    end
  end

  describe 'filter functionality' do
    context 'when filters are defined and used' do
      vars do
        filter_handler_class do
          Class.new(SteelWheel::Handler) do
            url_params do
              integer :id, presence: { message: "can't be blank" }
            end

            form do
              element :name do
                input type: :text
                output type: :string
              end

              element :status do
                input type: :text
                output type: :string
              end
            end

            filter :name do |scope, value|
              scope.select { |item| item.name.include?(value) }
            end

            filter :status do |scope, value|
              scope.select { |item| item.status == value }
            end

            filterable def users
              [
                OpenStruct.new(name: 'John Doe', status: 'active'),
                OpenStruct.new(name: 'Jane Smith', status: 'active'),
                OpenStruct.new(name: 'Bob Johnson', status: 'inactive')
              ]
            end

            def call
              { users: users }
            end
          end
        end
      end

      it 'applies filters to filterable method' do
        result = filter_handler_class.handle({ id: 1, name: 'John', status: 'active' })

        expect(result.users.length).to eq 1
        expect(result.users.first.name).to eq 'John Doe'
        expect(result.users.first.status).to eq 'active'
      end
    end
  end

  describe 'railtie helpers functionality' do
    context 'when testing RailsHelpers module' do
      before do
        stub_const('Rails', double('Rails'))
        allow(Rails).to receive(:root).and_return(double('root', join: '/path/to/public/404.html'))
      end

      vars do
        test_controller_class do
          Class.new do
            include SteelWheel::RailsHelpers

            attr_accessor :params, :view_context

            def initialize
              @params = { controller: 'users', action: 'index' }
              @view_context = Object.new
            end

            def render(options); end
          end
        end

        test_handler_class do
          Class.new(SteelWheel::Handler) do
            url_params do
              integer :id, presence: { message: "can't be blank" }
            end

            def call
              { result: 'success' }
            end
          end
        end
      end

      it 'resolves handler class names correctly for same namespace' do
        controller = test_controller_class.new

        # Create the Users module and handler class
        Users = Module.new
        Users::IndexHandler = Class.new(SteelWheel::Handler)
        handler_class = controller.handler_class_for('index')

        expect(handler_class).to eq Users::IndexHandler
      end

      it 'resolves handler class names for different namespace' do
        controller = test_controller_class.new

        # Create the Shared module and handler class
        Shared = Module.new
        Shared::UpdateHandler = Class.new(SteelWheel::Handler)
        handler_class = controller.handler_class_for('shared/update')

        expect(handler_class).to eq Shared::UpdateHandler
      end

      it 'sets up failure callbacks on handler' do
        controller = test_controller_class.new
        handler = test_handler_class.new({ id: 1 })
        controller.failure_callbacks(handler)

        expect(handler.callbacks[:not_found]).to be_a(Proc)
      end

      it 'executes failure callback and renders 404 page' do
        controller = test_controller_class.new
        handler = test_handler_class.new({ id: 1 })

        controller.failure_callbacks(handler)

        expect(controller).to receive(:render).with(
          file: '/path/to/public/404.html',
          status: handler.http_status
        )

        handler.callbacks[:not_found].call
      end

      it 'defines action method and executes handler' do
        controller_class = Class.new do
          include SteelWheel::RailsHelpers

          attr_accessor :params, :view_context

          def initialize
            @params = { controller: 'users', action: 'index' }
            @view_context = Object.new
          end

          def render(options); end
        end

        TestHandler = Class.new(SteelWheel::Handler) do
          url_params do
            integer :id, presence: { message: "can't be blank" }
          end

          def call
            { result: 'success' }
          end
        end

        controller_instance = controller_class.new
        controller_instance.params = { controller: 'users', action: 'test_action', id: 1 }

        # Create the expected handler class - the logic creates Users::TestActionHandler
        Users = Module.new unless defined?(Users)
        Users::TestActionHandler = Class.new(SteelWheel::Handler) do
          url_params do
            integer :id, presence: { message: "can't be blank" }
          end

          def call
            { result: 'success' }
          end
        end

        controller_class.action('test_action', handler: 'test_action') do |handler_instance|
          handler_instance.class == Users::TestActionHandler
        end
        result = controller_instance.test_action

        expect(result).to be_a(Users::TestActionHandler)
        expect(result.http_status).to eq(:ok)
      end
    end
  end
end
