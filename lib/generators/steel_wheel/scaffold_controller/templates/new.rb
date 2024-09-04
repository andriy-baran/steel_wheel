class <%= controller_class_name %>::NewHandler < ApplicationHandler
  define do
    query do
      def <%= singular_table_name %>
        <%= orm_class.build(class_name) %>
      end
    end
  end
end
