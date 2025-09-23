# frozen_string_literal: true

require 'steel_wheel/query/dependency_validator'
require 'steel_wheel/query/verify_validator'
require 'steel_wheel/query/exists_validator'

module SteelWheel
  # Base class that defines main flow
  class Handler
    include Memery
    include ActiveModel::Validations
    include SteelWheel::Filters
    include SteelWheel::Components
    include SteelWheel::Shortcuts
    include SteelWheel::Callbacks
    include SteelWheel::Preconditions

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
      prepare_params(params)
    end

    class << self
      def handle(action_name = nil, input = {}, &block)
        new(input).handle(action_name, &block)
      end

      def name
        to_s.match?(/Class/) ? 'SteelWheel::Handler' : to_s
      end

      def inherited(subclass)
        super
        subclass.url_params(url_params_definition)
        subclass.form(form_definition)
      end
    end

    def call
      raise SteelWheel::ActionNotImplementedError, 'Subclass must implement #call'
    end

    def handle(action_name = nil, &block)
      yield(self) if block
      validate_preconditions
      return unless success?
      return unless action_name

      send(action_name)
      success? ? success_callback : failure_callback
    end

    def success?
      http_status == :ok
    end

    def status
      return :ok if errors.empty?
      return errors.keys.first unless defined?(ActiveModel::Error)

      errors.map(&:type).first
    end

    private

    def prepare_params(params)
      params = if params.is_a?(Hash)
                 params.deep_symbolize_keys
               elsif params.is_a?(ActionController::Parameters)
                 params.to_unsafe_h.deep_symbolize_keys
               end
      @form_scope = self.class.form_definition.scope
      @validate_form = false
      if @form_scope
        @form_input = params.delete(@form_scope)
        @validate_form = @form_input.present?
      else
        @form_input = params
      end
      @input = params
    end
  end
end
