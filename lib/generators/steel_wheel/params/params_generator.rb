require_relative '../generic_generator'

module SteelWheel
  class ParamsGenerator < GenericGenerator
    setup_templates_root('params/templates')

    on_revoke do
      template 'params_template.rb', "app/params/#{file_path}_params.rb"
    end

    on_invoke do
      empty_directory Pathname.new('app/params').join(*class_path)
      template 'params_template.rb', "app/params/#{file_path}_params.rb"
    end
  end
end
