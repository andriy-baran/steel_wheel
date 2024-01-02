# frozen_string_literal: true

require 'steel_wheel/handler/validator'
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

    def initialize(&callbacks)
      @user_defined_callbacks = callbacks
    end

    def on_params_created(params, flow_name)
      # NOOP
    end

    def on_query_created(query, flow_name)
      # NOOP
    end

    def on_command_created(command, flow_name)
      # NOOP
    end

    def on_response_created(response, flow_name)
      # NOOP
    end

    def on_failure(flow)
      # NOOP
    end

    def on_success(flow)
      # NOOP
    end

    def self.base_class_for(factory, flow: :main)
      builders[flow].abstract_factory.factories[factory].base_class
    end

    def self.handle(input:, flow: :main, &block)
      new.handle(input: input, flow: flow, &block)
    end

    def handle(input:, flow: :main, &block)
      object = configure_builder(flow).wrap(delegate: true) do |i|
        i.params(input)
      end
      yield(object) if block
      Validator.run(object)
      object.success? ? on_success(object) : on_failure(object)
      object
    end

    private

    def configure_builder(flow)
      builder = self.class.builders[flow]
      builder.add_observer(self)
      builder = builder.with_callbacks(&user_defined_callbacks) if user_defined_callbacks
      builder
    end
  end
end
