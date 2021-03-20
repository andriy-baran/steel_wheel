module SteelWheel
  class GenericGenerator < Rails::Generators::NamedBase
    def self.setup_templates_root(templates_relative_path)
      source_root File.expand_path(templates_relative_path, __dir__)
    end

    def self.on_revoke(&block)
      block_given? ? @on_revoke = block : @on_revoke
    end

    def self.on_invoke(&block)
      block_given? ? @on_invoke = block : @on_invoke
    end

    def copy_files
      if behavior == :revoke
        instance_eval(&self.class.on_revoke)
      elsif behavior == :invoke
        instance_eval(&self.class.on_invoke)
      end
    end
  end
end
