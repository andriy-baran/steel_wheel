# frozen_string_literal: true

module SteelWheel
  class CommandGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def copy_files
      if behavior == :revoke
        template 'command_template.rb', "app/handlers/#{file_path}_handler/command.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/commands').join(*class_path)
        template 'command_template.rb', "app/handlers/#{file_path}_handler/command.rb"
      end
    end
  end
end
