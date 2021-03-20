require_relative '../generic_generator'

module SteelWheel
  class HandlerGenerator < GenericGenerator
    setup_templates_root('handler/templates')

    on_revoke do
      template 'handler_template.rb', "app/handlers/#{file_path}_handler.rb"
    end

    on_invoke do
      empty_directory Pathname.new('app/handlers').join(*class_path)
      template 'handler_template.rb', "app/handlers/#{file_path}_handler.rb"
    end
  end
end
