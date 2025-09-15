# frozen_string_literal: true

module SteelWheel
  # Provides callbacks functionality for handlers
  module Callbacks
    NOOP = ->(o) { o }.freeze

    def callbacks
      @callbacks ||= {}
    end

    def failure(status = :unprocessable_entity, &block)
      callbacks[status] = block
    end

    def success(&block)
      callbacks[:success] = block
    end

    private

    def success_callback
      callbacks.fetch(:success, NOOP).call(self)
    end

    def failure_callback
      callbacks.fetch(http_status, NOOP).call(self)
    end
  end
end
