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
    attr_accessor :http_status, :helpers

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
      @form_scope = self.class.form_definition.scope
      @form_input = @form_scope ? params.delete(@form_scope) : params
      @input = params
      @callbacks = { success: NOOP, failure: NOOP }
    end

    class << self
      attr_writer :params_definition, :form_definition

      def params_definition
        @params_definition ||= Class.new(SteelWheel::Params)
      end

      def form_definition
        @form_definition ||= Class.new(EasyForm::Rails::Base)
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

      def self.filter(name, &definition)
        define_method("filter_by_#{name}", &definition)
      end

      def self.filterable(name)
        alias_method :"initial_#{name}_scope", name
        define_method(name) do
          apply_filters(:"initial_#{name}_scope", form_params.to_h)
        end
      end
    end

    def params
      @params ||= self.class.params_definition.new(input)
    end

    def form_params
      @form_params ||= if @form_scope
                         self.class.form_definition.params_definition.schema[@form_scope].class.new(form_input)
                       else
                         self.class.form_definition.params_definition.new(form_input)
                       end
    end

    def form
      @form ||= self.class.form_definition.new(**form_attributes)
    end

    def on_preconditions_failure
      failure_callback
    end

    def on_preconditions_success
      # NOOP
    end

    def apply_filters(scope, search_params)
      search_params.each do |key, value|
        scope = send("filter_by_#{key}", scope, value) if value.present?
      end
      scope
    end


      raise NotImplementedError, 'Subclass must implement #call'
    end

    def handle(&block)
      yield(self) if block
      validate_preconditions(:params, :form, :self)
      return unless success?

      call
      success? ? success_callback : failure_callback
    end

    def ask
      validate_preconditions(:params, :self)
      success_callback if success?
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

    def validate_preconditions(*steps)
      if steps.include?(:params) && params.invalid?
        self.http_status = params.status
        errors.merge!(params.errors)
        on_preconditions_failure
      elsif steps.include?(:form) && form_params.invalid?
        self.http_status = :unprocessable_entity
        errors.merge!(form_params.errors)
        @form = form.with_errors(form_params)
        on_preconditions_failure
      elsif steps.include?(:self) && invalid?
        self.http_status = status
        on_preconditions_failure
      end
      on_preconditions_success
    end
  end
end
