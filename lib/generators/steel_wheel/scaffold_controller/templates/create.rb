class <%= controller_class_name %>::CreateHandler < ApplicationHandler
  define do
    <%- unless attributes.empty? -%>
    params do
      has :<%= singular_table_name %> do
        <%- simple_params.each do |attribute| -%>
        <%= convert_to_easy_params_type(attribute) %> :<%= attribute.column_name %>, presence: true
        <%- end -%>
      end
    end

    <%- end -%>
    query do
      def <%= singular_table_name %>
        <%= orm_class.build(class_name, "params.#{singular_table_name}.to_h") %>
      end
    end

    command do
      def call(*)
        <%= singular_table_name %>.save
      end
    end
  end

  def on_success(flow, name)
    flow.call(flow, name)
  end
end
