module SteelWheel
  class QueryGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def copy_files
      if behavior == :revoke
        template 'query_template.rb', "app/queries/#{file_path}_query.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/queries').join(*class_path)
        template 'query_template.rb', "app/queries/#{file_path}_query.rb"
      end
    end
  end
end
