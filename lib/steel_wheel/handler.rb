module SteelWheel
  class Handler < FlowObject::Base
    from :params
    to :response

    input :params, base_class: SteelWheel::Params, init: ->(klass, **value) { klass.new(**value) }
    flow do
      stage :action, base_class: SteelWheel::Action
    end
    output :response, base_class: SteelWheel::Response

    def self.accept(*values, &block)
      @initial_values = values
      after_flow_initialize(&block)
      self
    end

    def self.halt_flow?(object, id)
      !object.valid?
    end

    def on_params_failure
      output.errors = given.errors.full_messages
      output.status = :bad_request
    end

    def on_action_failure
      output.errors = given.errors.full_messages_for(given.error_key)
      output.status = given.error_key
    end

    def on_success
      # NOOP
    end
  end
end
