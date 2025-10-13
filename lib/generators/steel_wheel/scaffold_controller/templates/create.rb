class <%= controller_class_name %>::CreateHandler < ApplicationHandler
  form <%= controller_class_name %>::ModelForm

  verify memoize def <%= file_name %>
    <%= singular_name.camelize %>.new(form_params.to_h)
  end

  def form_attributes
    <%- if controller_class_path.empty? -%>
    { model: <%= file_name %> }
    <%- else -%>
    { model: [<%= controller_class_path.map{|path| ":#{path}"}.join(', ') %>, <%= file_name %>] }
    <%- end -%>
  end

  def on_validation_success
    call if current_action.create?
  end

  def call
    <%= file_name %>.save
  end
end
