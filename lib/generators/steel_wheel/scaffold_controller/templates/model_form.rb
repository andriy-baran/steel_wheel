module <%= controller_class_name %>
  class ModelForm < ActionForm::Rails::Base
    resource_model <%= class_name %>

    <%- simple_params.each do |attribute| -%>
    element :<%= attribute.column_name %> do
      <%- if attribute.type == :boolean -%>
      input(type: :checkbox)
      output(type: :boolean, presence: true)
      <%- elsif attribute.type == :text -%>
      input(type: :textarea)
      output(type: :string, presence: true)
      <%- elsif attribute.type == :decimal || attribute.type == :float -%>
      input(type: :number, step: 'any')
      output(type: :decimal, presence: true)
      <%- elsif attribute.type == :integer -%>
      input(type: :number)
      output(type: :integer, presence: true)
      <%- elsif attribute.type == :date -%>
      input(type: :date)
      output(type: :date, presence: true)
      <%- elsif attribute.type == :datetime || attribute.type == :timestamp -%>
      input(type: :datetime_local)
      output(type: :datetime, presence: true)
      <%- else -%>
      input(type: :text)
      output(type: :string, presence: true)
      <%- end -%>
    end

    <%- end -%>
  end
end
