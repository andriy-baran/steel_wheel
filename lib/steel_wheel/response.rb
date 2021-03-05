module SteelWheel
  class Response
    attr_accessor :status, :errors

    def initialize
      @status = :ok
    end

    def success?
      errors.nil?
    end
  end
end
