module SteelWheel
  module Flows
    module ApiJson
      class Result < OpenStruct; end

      module ClassMethods
        def inherited(subclass)
          super
          subclass.errors_format(&errors_format)
          subclass.from(self.in)
          subclass.to(self.out)
        end

        def errors_format(&block)
          block_given? ? @errors_format = block : @errors_format ||= ->(text) { { error: 'error', message: text } }
        end

        def controllers_cascade_decorating(previous_step, current_object, &block)
          raise(ArgumentError, 'Both arguments required') if previous_step.nil? ^ current_object.nil?
          error_track = false
          controllers.each do |controller, base_class|
            __sw_component_inactive_error__(controller).call if base_class.nil?
            block.call(current_object) if previous_step == :context && block_given?
            error_track = true and break if __sw_invalidate_state__(current_object)

            current_object = __sw_handle_step__(:controllers, previous_step, current_object, controller, base_class)
            previous_step = controller
          end
          SteelWheel::CascadingState.new(previous_step, current_object, error_track)
        end

        def prepare(previous_step = self.in, current_object = __sw_wrap_input__, &block)
          cascade = controllers_cascade_decorating(previous_step, current_object, &block)
          __sw_resolve_cascade__(cascade)
        end
      end

      module InstanceMethods
        def on_params_failure
          result.json = self.class.errors_format.call(given.errors.full_messages.join("\n")).to_json
          result.status = :bad_request
        end

        def on_context_failure
          errors = given.errors.full_messages_for(given.error_key).join("\n")
          result.json = self.class.errors_format.call(errors).to_json
          result.status = given.error_key
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
          input :params, base_class: SteelWheel::Params, init: ->(klass, value) { klass.new(value) }
          controller :context, base_class: SteelWheel::Context
          controller :action, base_class: SteelWheel::Action
          output :json, base_class: SteelWheel::Operation::Result, init: ->(klass) { klass.new({json: '{}', status: :ok}) }
        end
        receiver.singleton_class.send(:alias_method, :params, :params_input)
        receiver.singleton_class.send(:alias_method, :context, :context_controller)
        receiver.singleton_class.send(:alias_method, :action, :action_controller)
        receiver.singleton_class.send(:alias_method, :json, :json_output)
      end
    end
  end
end
