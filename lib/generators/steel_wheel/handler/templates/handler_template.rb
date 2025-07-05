class <%= class_name %>Handler < ApplicationHandler
  def call
    # NOOP
  end

  def on_validation_success
    call
  end
end
