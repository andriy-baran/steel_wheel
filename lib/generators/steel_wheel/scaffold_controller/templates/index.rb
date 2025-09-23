class <%= controller_class_name %>::IndexHandler < ApplicationHandler
  def form_attributes
    { method: :get, action: helpers.<%= index_helper %>_path, params: form_params }
  end

  form <%= controller_class_name %>::SearchForm

  <%- simple_params.each do |attribute| -%>
  filter :<%= attribute.column_name %> do |scope, value|
    scope.where(<%= attribute.column_name %>: value)
  end

  <%- end -%>
  filterable def <%= plural_table_name %>
    <%= class_name %>.all
  end
end
