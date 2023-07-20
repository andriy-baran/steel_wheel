# frozen_string_literal: true

module SteelWheel
  class HandlerGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def copy_files
      if behavior == :revoke
        template 'handler_template.rb', "app/handlers/#{file_path}_handler.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/handlers').join(*class_path)
        template 'handler_template.rb', "app/handlers/#{file_path}_handler.rb"
      end
    end
  end
end
