class <%= controller_class_name %>::CreateHandler < ApplicationHandler
  form <%= controller_class_name %>::ModelForm

  verify memoize def <%= singular_table_name %>
    <%= class_name %>.new(form_params.to_h)
  end

  def form_attributes
    { model: <%= singular_table_name %> }
  end

  def call
    <%= singular_table_name %>.save
  end
end
