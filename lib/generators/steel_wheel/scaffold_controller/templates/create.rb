class <%= controller_class_name %>::CreateHandler < ApplicationHandler
  <%- unless attributes.empty? -%>
  params do
    has :<%= singular_table_name %> do
      <%- simple_params.each do |attribute| -%>
      <%= convert_to_easy_params_type(attribute) %> :<%= attribute.column_name %>, presence: true
      <%- end -%>
    end
  end

  <%- end -%>
  def <%= singular_table_name %>
    <%= orm_class.build(class_name, "params.#{singular_table_name}.to_h") %>
  end

  def call
    <%= singular_table_name %>.save
  end

  def on_validation_success
    call
  end
end
