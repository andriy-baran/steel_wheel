# frozen_string_literal: true

module SteelWheel
  class ParamsGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def copy_files
      if behavior == :revoke
        template 'params_template.rb', "app/params/#{file_path}_params.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/params').join(*class_path)
        template 'params_template.rb', "app/params/#{file_path}_params.rb"
      end
    end
  end
end
