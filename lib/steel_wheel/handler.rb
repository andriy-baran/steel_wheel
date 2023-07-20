# frozen_string_literal: true

module SteelWheel
  # Base class that defines main flow
  class Handler
    include Nina
    include ActiveModel::Validations

    attr_reader :user_defined_callbacks

    builder :main do
      factory :params, produces: SteelWheel::Params
      factory :query, produces: SteelWheel::Query
      factory :command, produces: SteelWheel::Command
      factory :response, produces: SteelWheel::Response
    end

    def self.define(flow: :main, &block)
      builders[flow].subclass(&block)
    end

    # Runs validation on objects
    class Validator
      include ActiveModel::Validations
      attr_accessor :http_status

      def self.run(flow)
        validator = new
        [flow.params, flow.query, flow.command].each do |obj|
          break if validator.errors.any?

          validator.validate(obj)
        end
        flow.status = validator.http_status || :ok
        flow.errors.merge!(validator.errors)
      end

      def validate(object)
        return if object.valid?

        self.http_status ||= object.http_status
        errors.merge!(object.errors) if errors.empty?
      end
    end

    def initialize(&callbacks)
      @user_defined_callbacks = callbacks
    end

    def on_params_created(params)
      # NOOP
    end

    def on_query_created(query)
      # NOOP
    end

    def on_command_created(command)
      # NOOP
    end

    def on_response_created(command)
      # NOOP
    end

    def on_failure(flow)
      # NOOP
    end

    def on_success(flow)
      # NOOP
    end

    def self.handle(input:, flow: :main, &block)
      new.handle(input: input, flow: flow, &block)
    end

    def handle(input:, flow: :main, &block)
      object = configure_builder(flow).wrap(delegate: true) { |i| i.params(input) }
      yield(object) if block
      Validator.run(object)
      object.success? ? on_success(object) : on_failure(object)
      object
    end

    private

    def configure_builder(flow)
      builder = self.class.builders[flow].with_callbacks(&required_callbacks)
      builder = builder.with_callbacks(&user_defined_callbacks) if user_defined_callbacks
      builder
    end

    def required_callbacks
      lambda do |c|
        c.params { |o| on_params_created(o) }
        c.query { |o| on_query_created(o) }
        c.command { |o| on_command_created(o) }
        c.response { |o| on_response_created(o) }
      end
    end
  end
end
