module SteelWheel
  module Flows
    module ApiJson
      class Result < OpenStruct; end

      module ClassMethods
        def inherited(subclass)
          super
          subclass.errors_format(&self.errors_format)
        end

        def errors_format(&block)
          block_given? ? @errors_format = block : @errors_format ||= ->(text) { { error: 'error', message: text } }
        end
      end

      module InstanceMethods
        def on_params_input_failure
          output.json = self.class.errors_format.call(given.errors.full_messages.join("\n")).to_json
          output.status = :bad_request
        end

        def on_context_stage_failure
          errors = given.errors.full_messages_for(given.error_key).join("\n")
          output.json = self.class.errors_format.call(errors).to_json
          output.status = given.error_key
        end

        def on_success
          # NOOP
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          from :params
          to :json
          input :params, base_class: SteelWheel::Params, init: ->(klass, *value) { klass.new(*value) }
          flow do
            stage :context, base_class: SteelWheel::Context
            stage :action, base_class: SteelWheel::Action
          end
          output :json, base_class: SteelWheel::Flows::ApiJson::Result, init: ->(klass) { klass.new({json: '{}', status: :ok}) }
        end
        # receiver.singleton_class.send(:alias_method, :params, :params_input)
        # receiver.singleton_class.send(:alias_method, :context, :context_stage)
        # receiver.singleton_class.send(:alias_method, :action, :action_stage)
        # receiver.singleton_class.send(:alias_method, :json, :json_output)
      end
    end
  end
end
