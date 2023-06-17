class <%= class_name %>Handler < ApplicationHandler
  define do
    params do

    end

    query do

    end

    command do
      def call
        # NOOP
      end
    end

    def on_success(flow)
      flow.call
    end
  end
end
