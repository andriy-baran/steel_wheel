class <%= controller_class_name %>::UpdateHandler < ApplicationHandler
  form <%= controller_class_name %>::ModelForm

  url_params do
    integer :id, presence: true
  end

  finder :<%= singular_table_name %>, -> { <%= class_name %>.find_by(id: url_params.id) }, validate_existence: true

  def on_validation_success
    call if current_action.update?
    destroy if current_action.destroy?
  end

  def call
    <%= singular_table_name %>.update(form_params.to_h)
  end

  def destroy
    <%= singular_table_name %>.destroy
  end

  def form_attributes
    { model: <%= singular_table_name %> }
  end
end

