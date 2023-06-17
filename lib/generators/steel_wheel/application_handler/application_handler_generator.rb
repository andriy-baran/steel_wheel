# frozen_string_literal: true

module SteelWheel
  class ApplicationHandlerGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def copy_files
      empty_directory Pathname.new('app/handlers')
      template 'handler_template.rb', 'app/handlers/application_handler.rb'
    end
  end
end
