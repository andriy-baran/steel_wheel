class <%= controller_class_name %>::IndexHandler < ApplicationHandler
  define do
    query do
      def <%= plural_table_name %>
        <%= orm_class.all(class_name) %>
      end
    end
  end
end
