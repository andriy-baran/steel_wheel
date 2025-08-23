# frozen_string_literal: true

require 'steel_wheel/query/dependency_validator'
require 'steel_wheel/query/verify_validator'
require 'steel_wheel/query/exists_validator'

module SteelWheel
  # Base class that defines main flow
  class Handler
    include Memery
    include ActiveModel::Validations

    NOOP = ->(o) { o }.freeze

    attr_reader :input, :form_input
    attr_accessor :http_status

    unless defined?(ActiveModel::Error)
      def self.generic_validation_keys(*keys)
        include SteelWheel::SkipActiveModelErrorsKeys[*keys]
      end

      generic_validation_keys(:not_found, :forbidden, :unprocessable_entity, :bad_request, :unauthorized)
    end

    def initialize(params = {})
      @http_status = :ok
      if params.is_a?(Hash)
        params = params.deep_symbolize_keys
      elsif params.is_a?(ActionController::Parameters)
        params = params.to_unsafe_h.deep_symbolize_keys
      end
      @form_input = self.class.form_definition.scope ? params.delete(self.class.form_definition.scope) : params
      @input = params
      @callbacks = { success: NOOP, failure: NOOP }
    end

    class << self
      attr_writer :params_definition, :form_definition

      def params_definition
        @params_definition ||= Class.new(SteelWheel::Params)
      end

      def form_definition
        @form_definition ||= Class.new(EasyForm::Base)
      end

      def params(klass = nil, &block)
        self.params_definition = klass if klass
        params_definition.class_exec(self, &block) if block
      end

      def form(klass = nil, &block)
        self.form_definition = klass if klass
        form_definition.class_eval(&block) if block
      end

      def handle(input = {}, &block)
        new(input).handle(&block)
      end

      def name
        to_s.match?(/Class/) ? 'SteelWheel::Handler' : to_s
      end

      def depends_on(*attrs, validate_provided: true)
        attr_accessor(*attrs)

        validates(*attrs, 'steel_wheel/query/dependency': validate_provided)
      end

      def verify(*attrs, valid: true)
        validates(*attrs, 'steel_wheel/query/verify': valid)
      end

      def finder(name, scope, validate_existence: false)
        define_method(name) do
          instance_exec(&scope)
        end
        memoize name
        validates name, 'steel_wheel/query/exists': validate_existence
      end
    end

    def params
      @params ||= self.class.params_definition.new(input)
    end

    def form_params
      @form_params ||= self.class.form_definition.params_definition.new(form_input)
    end

    # def form_params_definition
    #   klass = self.class.form_definition.params_definition
    #   scope = self.class.form_definition.scope
    #   Class.new(klass) do
    #     has scope, klass
    #   end
    # end

    def form
      model = form_attributes[:model].is_a?(Array) ? form_attributes[:model].last : form_attributes[:model]
      # if form_params.errors.any? && model
      #   action = form_attributes.fetch(:action, helpers.polymorphic_path(form_attributes[:model]))
      #   form_params.define_singleton_method(:persisted?) { model.persisted? }
      #   form_params.define_singleton_method(:model_name) { model.model_name }
      #   self.class.form_definition.new(action: action, model: form_params, errors: form_params.errors)
      # else
      #   self.class.form_definition.new(**form_attributes, errors: errors)
      # end
      if model && form_params.errors.any?
        model.assign_attributes(form_params.to_h)
      end
      self.class.form_definition.new(**form_attributes, errors: errors)
    end

    def on_preconditions_failure
      failure_callback
    end

    def on_preconditions_success
      # NOOP
    end

    def call
      raise NotImplementedError, 'Subclass must implement #call'
    end

    def handle(&block)
      yield(self) if block
      validate_preconditions
      return unless success?

      call
      success? ? success_callback : failure_callback
    end

    def success?
      errors.empty?
    end

    def status
      return :ok if errors.empty?
      return errors.keys.first unless defined?(ActiveModel::Error)

      errors.map(&:type).first
    end

    def failure(&block)
      @callbacks[:failure] = block
    end

    def success(&block)
      @callbacks[:success] = block
    end

    private

    def success_callback
      @callbacks[:success].call(self)
    end

    def failure_callback
      @callbacks[:failure].call(self)
    end

    def validate_preconditions
      if params.invalid?
        self.http_status = params.status
        errors.merge!(params.errors)
        on_preconditions_failure
      elsif form_params.invalid?
        self.http_status = :unprocessable_entity
        errors.merge!(form_params.errors)
        on_preconditions_failure
      elsif invalid?
        self.http_status = status
        on_preconditions_failure
      end
      on_preconditions_success
    end
  end
end
