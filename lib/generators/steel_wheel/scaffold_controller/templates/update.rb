class <%= controller_class_name %>::UpdateHandler < ApplicationHandler
  define do
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

    query do
      finder :<%= singular_table_name %>, -> { <%= class_name %>.find_by(id: id) }, existence: true
    end

    command do
      def call(*)
        <%= singular_table_name %>.update!(params.<%= singular_table_name %>.to_h)
      end
    end
  end

  def on_success(flow, name)
    flow.call(flow, name)
  end
end
