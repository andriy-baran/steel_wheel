module SteelWheel
  class Params < EasyParams::Base
    def http_status
      return :ok if errors.empty?

      :bad_request
    end
  end
end
