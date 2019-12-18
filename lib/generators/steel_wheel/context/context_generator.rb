module SteelWheel
  class ContextGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def copy_files
      if behavior == :revoke
        template 'context_template.rb', "app/contexts/#{file_path}_context.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/contexts').join(*class_path)
        template 'context_template.rb', "app/contexts/#{file_path}_context.rb"
      end
    end
  end
end
