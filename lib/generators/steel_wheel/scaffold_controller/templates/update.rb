class <%= controller_class_name %>::UpdateHandler < ApplicationHandler
  form <%= controller_class_name %>::ModelForm

  url_params do
    integer :id, presence: true
  end

  finder :<%= file_name %>, -> { <%= singular_name.camelize %>.find_by(id: url_params.id) }, validate_existence: true

  def on_validation_success
    call if current_action.update?
    destroy if current_action.destroy?
  end

  def call
    <%= file_name %>.update(form_params.to_h)
  end

  def destroy
    <%= file_name %>.destroy
  end

  def form_attributes
    <%- if controller_class_path.empty? -%>
    { model: <%= file_name %> }
    <%- else -%>
    { model: [<%= controller_class_path.map{|path| ":#{path}"}.join(', ') %>, <%= file_name %>] }
    <%- end -%>
  end
end

