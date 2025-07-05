# frozen_string_literal: true

require 'steel_wheel/query/dependency_validator'
require 'steel_wheel/query/verify_validator'
require 'steel_wheel/query/exists_validator'

module SteelWheel
  # Base class that defines main flow
  class Handler
    include Memery
    include ActiveModel::Validations

    attr_reader :params
    attr_accessor :http_status

    unless defined?(ActiveModel::Error)
      def self.generic_validation_keys(*keys)
        include SteelWheel::SkipActiveModelErrorsKeys[*keys]
      end

      generic_validation_keys(:not_found, :forbidden, :unprocessable_entity, :bad_request, :unauthorized)
    end

    def initialize(params)
      @http_status = :ok
      @params = params
    end

    class << self
      attr_accessor :params_definition

      def params(klass = nil, &block)
        self.params_definition = klass || Class.new(SteelWheel::Params, &block)
      end

      def handle(input:, &block)
        params = params_definition.new(input)
        new(params).handle(&block)
      end

      def name
        to_s.match?(/Class/) ? 'SteelWheel::Handler' : to_s
      end

      def depends_on(*attrs, provided: false)
        attr_accessor(*attrs)

        validates(*attrs, 'steel_wheel/query/dependency': provided)
      end

      def verify(*attrs)
        validates(*attrs, 'steel_wheel/query/verify': true)
      end

      def finder(name, scope, existence: false)
        define_method(name) do
          instance_exec(&scope)
        end
        memoize name
        validates name, 'steel_wheel/query/exists': existence
      end
    end

    self.params_definition = Class.new(SteelWheel::Params)

    def on_validation_failure
      # NOOP
    end

    def on_validation_success
      # NOOP
    end

    def handle(&block)
      yield(self) if block
      if params.invalid?
        self.http_status = params.status
        errors.merge!(params.errors)
        on_validation_failure
      else
        valid? ? on_validation_success : on_validation_failure
      end
      self
    end

    def success?
      errors.empty?
    end

    def status
      return :ok if errors.empty?
      return errors.keys.first unless defined?(ActiveModel::Error)

      errors.map(&:type).first
    end
  end
end
