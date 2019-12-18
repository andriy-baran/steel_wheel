module SteelWheel
  class ActionGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def copy_files
      if behavior == :revoke
        template 'action_template.rb', "app/actions/#{file_path}_action.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/actions').join(*class_path)
        template 'action_template.rb', "app/actions/#{file_path}_action.rb"
      end
    end
  end
end
