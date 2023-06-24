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
      self.http_status ||= params.http_status
      errors.merge!(params.errors) if errors.empty?
    end

    def on_query_success(query)
      # NOOP
    end

    def on_query_failure(query)
      self.http_status ||= query.http_status
      errors.merge!(query.errors) if errors.empty?
    end

    def on_command_success(command)
      # NOOP
    end

    def on_command_failure(command)
      self.http_status ||= command.http_status
      errors.merge!(command.errors) if errors.empty?
    end

    def on_params_created(params)
      return on_params_failure(params) if params.invalid?

      on_params_success(params)
    end

    def on_query_created(query)
      return if errors.any?
      return on_query_failure(query) if query.invalid?

      on_query_success(query)
    end

    def on_command_created(command)
      return if errors.any?
      return on_command_failure(command) if command.invalid?

      on_command_success(command)
    end

    def on_complete(flow)
      return on_success(flow) if flow.success?

      on_failure(flow)
    end

    def on_failure(flow)
      # NOOP
    end

    def on_success(flow)
      # NOOP
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.handle(input:, flow: :main, &block)
      handler = new
      builder = builders[flow].with_callbacks do |c|
        c.params do |o|
          handler.on_params_created(o)
        end
        c.query do |o|
          block&.call(o)
          handler.on_query_created(o)
        end
        c.command do |o|
          handler.on_command_created(o)
        end
      end
      flow = builder.wrap(delegate: true) do |i|
        i.params(input)
        i.response(handler)
      end
      flow.tap { |f| handler.on_complete(f) }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
