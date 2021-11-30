require_relative '../generic_generator'

module SteelWheel
  class CommandGenerator < GenericGenerator
    setup_templates_root('command/templates')

    on_revoke do
      template 'command_template.rb', "app/commands/#{file_path}_command.rb"
    end

    on_invoke do
      empty_directory Pathname.new('app/commands').join(*class_path)
      template 'command_template.rb', "app/commands/#{file_path}_command.rb"
    end
  end
end
