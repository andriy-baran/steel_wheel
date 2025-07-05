class <%= controller_class_name %>::IndexHandler < ApplicationHandler
  def <%= plural_table_name %>
    <%= orm_class.all(class_name) %>
  end
end
