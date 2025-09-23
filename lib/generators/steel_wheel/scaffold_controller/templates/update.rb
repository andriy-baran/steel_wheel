class <%= controller_class_name %>::UpdateHandler < ApplicationHandler
  form <%= controller_class_name %>::ModelForm

  params do
    integer :id, presence: true
  end

  finder :<%= singular_table_name %>, -> { <%= class_name %>.find_by(id: params.id) }, validate_existence: true

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

