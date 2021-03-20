require_relative '../generic_generator'

module SteelWheel
  class ActionGenerator < GenericGenerator
    setup_templates_root('action/templates')

    on_revoke do
      template 'action_template.rb', "app/actions/#{file_path}_action.rb"
    end

    on_invoke do
      empty_directory Pathname.new('app/actions').join(*class_path)
      template 'action_template.rb', "app/actions/#{file_path}_action.rb"
    end
  end
end
