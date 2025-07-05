class <%= controller_class_name %>::UpdateHandler < ApplicationHandler
  params do
    integer :id, presence: true
    <%- unless attributes.empty? -%>
    has :<%= singular_table_name %> do
      <%- simple_params.each do |attribute| -%>
      <%= convert_to_easy_params_type(attribute) %> :<%= attribute.column_name %>
      <%- end -%>
    end
    <%- end -%>
  end

  finder :<%= singular_table_name %>, -> { <%= class_name %>.find_by(id: params.id) }, existence: true

  def call
    <%= singular_table_name %>.update!(params.<%= singular_table_name %>.to_h)
  end

  def on_validation_success
    call
  end
end

