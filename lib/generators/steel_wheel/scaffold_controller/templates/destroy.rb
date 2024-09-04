class <%= controller_class_name %>::DestroyHandler < ApplicationHandler
  define do
    <%- unless attributes.empty? -%>
    params do
      integer :id, presence: true
    end

    <%- end -%>
    query do
      finder :<%= singular_table_name %>, -> { <%= class_name %>.find_by(id: id) }, existence: true
    end

    command do
      def call(*)
        <%= singular_table_name %>.destroy
      end
    end
  end

  def on_success(flow, name)
    flow.call(flow, name)
  end
end
