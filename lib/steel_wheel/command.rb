# frozen_string_literal: true

module SteelWheel
  # Base class for commands
  class Command
    include Memery
    include ActiveModel::Validations

    def self.name
      'SteelWheel::Command'
    end

    def http_status
      return :ok if errors.empty?
      return errors.keys.first unless defined?(ActiveModel::Error)

      errors.map(&:type).first
    end

    def call(*)
      # NOOP
    end
  end
end
