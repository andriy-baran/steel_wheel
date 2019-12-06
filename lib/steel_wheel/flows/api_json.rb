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
          subclass.result_attrs = result_attrs
        end

        def errors_format(&block)
          block_given? ? @errors_format = block : @errors_format ||= ->(text) { { error: 'error', message: text } }
        end

        def controllers_cascade_decorating(cascade, &block)
          controllers.each do |controller, base_class|
            __sw_component_inactive_error__(controller).call if base_class.nil?
            block.call(cascade.current_object) if cascade.previous_step == :context && block_given?
            cascade.failure and break if __sw_invalidate_state__(cascade.current_object)

            __sw_handle_step__(cascade, base_class, controller)
          end
        end

        def prepare(cascade = SteelWheel::CascadingState.new, &block)
          if cascade.first_step?
            cascade.previous_step = self.in
            cascade.current_object = __sw_wrap_input__
            cascade.inc_step
          end
          controllers_cascade_decorating(cascade, &block)
          __sw_resolve_cascade__(cascade)
        end
      end

      module InstanceMethods
        def initialize(given)
          @given = given
          @result = Result.new(text: {}.to_json, content_type: 'application/json', status: :ok)
        end

        def on_failure(failed_step)
          if failed_step == :params
            result.text = self.class.errors_format.call(given.errors.full_messages.join("\n")).to_json
            result.status = :bad_request
          elsif failed_step == :context
            errors = given.errors.full_messages_for(given.error_key).join("\n")
            result.text = self.class.errors_format.call(errors).to_json
            result.status = given.error_key
          else
            # NOOP
          end
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
          input :params, base_class: SteelWheel::Params
          controller :context, base_class: SteelWheel::Context
          controller :action, base_class: SteelWheel::Action
          output :json, base_class: SteelWheel::Operation::Result
        end
      end
    end
  end
end
