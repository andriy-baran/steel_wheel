module SteelWheel
  module Flows
    module ApiJson
      class Result < OpenStruct; end

      module NOOP
        def call(*); end
      end

      module ClassMethods
        def inherited(subclass)
          subclass.errors_format(&self.errors_format)
          super
        end

        def errors_format(&block)
          block_given? ? @errors_format = block : @errors_format ||= ->(text){{error: 'error',message: text}}
        end

        def from_params(params, &block)
          raise "#{self.name} has no params defined. Please use params {} or params <class name> to define it." if params_class.nil?
          raise "#{self.name} has no context defined. Please use context {} or context <class name> to define it." if context_class.nil?
          raise "#{self.name} has no action defined. Please use action {} or action <class name> to define it." if action_class.nil?
          create_params = ->(params) { params_class.new(params) }
          create_context = ->(attributes) { context_class.new(attributes) }
          create_action = ->(context) { action_class.new(context) }
          create_op = ->(action) { new(action) }
          create_noop = ->(result) { new(nil, result).tap{|op| op.singleton_class.prepend(NOOP) } }
          create_result = ->(status, text) { Result.new(content_type: 'application/json', status: status, text: text) }.curry
          error_json_result = ->(text, status) { create_result.call(status).call(errors_format.call(text).to_json)  }
          create_noop_error_json = ->(text, status){
            create_noop.call(error_json_result.call(text, status))
          }
          flow = ->(success, error) {
            params_object = create_params.call(params)
            params_object.invalid? and return error.call(params_object.errors.full_messages.join("\n"), :bad_request)
            context = create_context.call(params_object.attributes)
            block.call(context) if block_given?
            context.invalid? and return error.call(context.errors.full_messages_for(context.error_key).join("\n"), context.error_key)
            success.call(create_action.call(context))
          }
          flow.call(create_op, create_noop_error_json)
        end
      end

      module Initializer
        attr_reader :action, :result
        def initialize(action, result = Result.new(text: {}.to_json, content_type:  'application/json', status: :ok))
          @action = action
          @result = result
        end
      end

      module InstanceMethods
        # Nothing here for now
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, Initializer
        receiver.class_eval do
          controller :params, base_class: SteelWheel::Params
          controller :context, base_class: SteelWheel::Context
          controller :action, base_class: SteelWheel::Action
        end
      end
    end
  end
end
