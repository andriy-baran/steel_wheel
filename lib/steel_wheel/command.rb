module SteelWheel
  class Command
    include Memery
    include ActiveModel::Validations

    def self.name
      'SteelWheel::Command'
    end

    def http_status
      errors.keys.first
    end

    def call
      # NOOP
    end
  end
end
