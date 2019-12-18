module SteelWheel
  class OperationGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def copy_files
      if behavior == :revoke
        template 'operation_template.rb', "app/operations/#{file_path}_operation.rb"
      elsif behavior == :invoke
        empty_directory Pathname.new('app/operations').join(*class_path)
        template 'operation_template.rb', "app/operations/#{file_path}_operation.rb"
      end
    end
  end
end
