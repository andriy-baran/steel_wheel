# frozen_string_literal: true

module SteelWheel
  # Base class for params
  class Params < EasyParams::Base
    def self.name
      'SteelWheel::Params'
    end

    def status
      return :ok if errors.empty?

      :bad_request
    end
  end
end
