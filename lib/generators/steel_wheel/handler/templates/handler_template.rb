class <%= class_name %>Handler < ApplicationHandler
  def call
    # NOOP
  end

  def on_validation_success
    # call if current_action.create?
    # update if current_action.update?
  end
end
