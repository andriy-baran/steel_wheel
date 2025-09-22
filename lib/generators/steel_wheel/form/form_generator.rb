# frozen_string_literal: true

module SteelWheel
  class FormGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def copy_files
      if behavior == :revoke
        template 'form_template.rb', "app/handlers/#{file_path}_form.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/handlers').join(*class_path)
        template 'form_template.rb', "app/handlers/#{file_path}_form.rb"
      end
    end
  end
end
