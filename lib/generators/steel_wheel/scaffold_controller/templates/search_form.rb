module <%= controller_class_name %>
  class SearchForm < EasyForm::Base
    <%- simple_params.each do |attribute| -%>
    element :<%= attribute.column_name %> do
      <%- if attribute.type == :boolean -%>
      input(type: :checkbox)
      output(type: :boolean)
      <%- elsif attribute.type == :text -%>
      input(type: :textarea)
      output(type: :string)
      <%- elsif attribute.type == :decimal || attribute.type == :float -%>
      input(type: :number, step: 'any')
      output(type: :decimal)
      <%- elsif attribute.type == :integer -%>
      input(type: :number)
      output(type: :integer)
      <%- elsif attribute.type == :date -%>
      input(type: :date)
      output(type: :date)
      <%- elsif attribute.type == :datetime || attribute.type == :timestamp -%>
      input(type: :datetime_local)
      output(type: :datetime)
      <%- else -%>
      input(type: :text)
      output(type: :string)
      <%- end -%>
    end

    <%- end -%>
  end
end
