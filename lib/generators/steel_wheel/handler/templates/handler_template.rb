class <%= class_name %>Handler < ApplicationHandler
  params_input do

  end

  command_stage do
    def call
      # NOOP
    end
  end

  def on_success
    flow.call
  end
end
