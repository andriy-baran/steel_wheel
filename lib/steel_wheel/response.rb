# frozen_string_literal: true

module SteelWheel
  # Base class for responses
  class Response
    attr_accessor :status

    include ActiveModel::Validations

    unless defined?(ActiveModel::Error)
      def self.generic_validation_keys(*keys)
        include SteelWheel::SkipActiveModelErrorsKeys[*keys]
      end

      generic_validation_keys(:not_found, :forbidden, :unprocessable_entity, :bad_request, :unauthorized)
    end

    def self.name
      'SteelWheel::Response'
    end

    def initialize
      @status = :ok
    end

    def success?
      errors.empty?
    end

    def valid?
      success?
    end
  end
end
