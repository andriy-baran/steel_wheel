module SteelWheel
  class Response
    attr_accessor :status
    attr_writer :errors
    include ActiveModel::Validations

    def self.generic_validation_keys(*keys)
      include SteelWheel::SkipActiveModelErrorsKeys[*keys]
    end

    generic_validation_keys(:not_found, :forbidden, :unprocessable_entity)

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
