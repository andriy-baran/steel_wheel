require_relative '../generic_generator'

module SteelWheel
  class CommandGenerator < GenericGenerator
    setup_templates_root('query/templates')

    on_revoke do
      template 'query_template.rb', "app/queries/#{file_path}_query.rb"
    end

    on_invoke do
      empty_directory Pathname.new('app/queries').join(*class_path)
      template 'query_template.rb', "app/queries/#{file_path}_query.rb"
    end
  end
end
