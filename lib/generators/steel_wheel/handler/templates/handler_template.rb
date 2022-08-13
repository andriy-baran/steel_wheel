class <%= class_name %>Handler < ApplicationHandler
  params do

  end

  query do

  end

  command do
    def call
      # NOOP
    end
  end

  def on_success
    flow.call
  end
end
