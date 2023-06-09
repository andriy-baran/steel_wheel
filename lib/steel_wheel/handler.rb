module SteelWheel
  class Handler
    include Nina
    include ActiveModel::Validations

    attr_accessor :http_status

    builder :main do
      factory :params, produces: SteelWheel::Params
      factory :query, produces: SteelWheel::Query
      factory :command, produces: SteelWheel::Command
      factory :response, produces: SteelWheel::Response
    end

    def on_params_failure(params)
      self.http_status = params.http_status
      errors.merge!(params.errors)
    end

    def on_query_failure(query)
      self.http_status = query.http_status
      errors.merge!(query.errors)
    end

    def on_command_failure(command)
      self.http_status = command.http_status
      errors.merge!(command.errors)
    end

    def on_success
      # NOOP
    end

    def self.handle(input:, flow: :main, &block)
      handler = new
      builder = builders[flow].with_callbacks do |c|
        c.params { |o| handler.on_params_failure(o) if o.invalid? }
        c.query do |o|
          block.call(o) if block
          handler.on_query_failure(o) if o.invalid?
        end
        c.command { |o| handler.on_command_failure(o) if o.invalid? }
        c.response {}
      end
      builder.wrap(delegate: true) do |i|
        i.params(input)
        i.response(handler)
      end
    end
  end
end
