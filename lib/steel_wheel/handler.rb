module SteelWheel
  class Handler < FlowObject::Base
    from :params
    to :response

    input :params, base_class: SteelWheel::Params
    flow do
      stage :query, base_class: SteelWheel::Query
      stage :command, base_class: SteelWheel::Command
    end
    output :response, base_class: SteelWheel::Response

    def self.halt_flow?(object, id)
      !object.valid?
    end

    def on_params_failure
      output.status = :bad_request
      output.errors.merge!(output.params.errors)
    end

    def on_query_failure
      output.status = output.query.http_status
      output.errors.merge!(output.query.errors)
    end

    def on_command_failure
      output.status = output.command.http_status
      output.errors.merge!(output.command.errors)
    end

    def on_success
      # NOOP
    end

    def self.handle(input:, flow: :main, &block)
      call(input: input, flow: flow) do |callbacks|
        callbacks.flow_initialized(&block) if block
      end
    end

    alias_method(:flow, :output)
    class << self
      alias_method :params, :params_input
      alias_method :query, :query_stage
      alias_method :command, :command_stage
      alias_method :response, :response_output
    end
  end
end
