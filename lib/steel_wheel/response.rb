module SteelWheel
  class Response
    attr_accessor :status
    attr_writer :errors
    include ActiveModel::Validations

    def initialize
      @status = :ok
    end

    def success?
      errors.empty?
    end
  end
end
