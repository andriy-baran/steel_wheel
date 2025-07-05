class <%= controller_class_name %>::NewHandler < ApplicationHandler
  def <%= singular_table_name %>
    <%= orm_class.build(class_name) %>
  end
end
