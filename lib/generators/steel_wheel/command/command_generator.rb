# frozen_string_literal: true

module SteelWheel
  class CommandGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def copy_files
      if behavior == :revoke
        template 'command_template.rb', "app/commands/#{file_path}_command.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/commands').join(*class_path)
        template 'command_template.rb', "app/commands/#{file_path}_command.rb"
      end
    end
  end
end
