# frozen_string_literal: true

module SteelWheel
  # Base class that defines main flow
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

    def self.define(flow: :main, &block)
      builders[flow].subclass(&block)
    end

    def on_params_success(params)
      # NOOP
    end

    def on_params_failure(params)
      self.http_status = params.http_status
      errors.merge!(params.errors)
    end

    def on_query_success(query)
      # NOOP
    end

    def on_query_failure(query)
      self.http_status = query.http_status
      errors.merge!(query.errors)
    end

    def on_command_success(command)
      # NOOP
    end

    def on_command_failure(command)
      self.http_status = command.http_status
      errors.merge!(command.errors)
    end

    def on_success(flow)
      # NOOP
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.handle(input:, flow: :main, &block)
      handler = new
      builder = builders[flow].with_callbacks do |c|
        c.params do |o|
          if o.invalid?
            handler.on_params_failure(o)
          else
            handler.on_params_success(o)
          end
        end
        c.query do |o|
          block&.call(o)
          if o.invalid?
            handler.on_query_failure(o)
          else
            handler.on_query_success(o)
          end
        end
        c.command do |o|
          if o.invalid?
            handler.on_command_failure(o)
          else
            handler.on_command_success(o)
          end
        end
      end
      flow = builder.wrap(delegate: true) do |i|
        i.params(input)
        i.response(handler)
      end
      handler.on_success(flow)
      flow
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
