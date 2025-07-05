class <%= controller_class_name %>::DestroyHandler < ApplicationHandler
  <%- unless attributes.empty? -%>
  params do
    integer :id, presence: true
  end

  <%- end -%>
  query do
    finder :<%= singular_table_name %>, -> { <%= class_name %>.find_by(id: params.id) }, existence: true
  end

  def call
    <%= singular_table_name %>.destroy
  end

  def on_validation_success
    call
  end
end
