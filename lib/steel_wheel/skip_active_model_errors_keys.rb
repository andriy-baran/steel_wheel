module SteelWheel
  module SkipActiveModelErrorsKeys
    def self.build_module
      mod = Module.new do
        class << self
          attr_accessor :skip_keys

          def extended(klass)
            klass.include self
          end
        end
      end
    end

    def self.patch_errors_method_on_instance(mod, klass)
      class << klass
        alias_method :__new__, :new
      end

      klass.define_singleton_method :new do |*args|
        instance = __new__(*args)
        instance.errors.define_singleton_method :full_message do |attribute, message|
          return message if mod.skip_keys.include?(attribute)
          super(attribute, message)
        end
        instance
      end
    end

    def self.[](*skip_keys)
      mod = build_module
      mod.skip_keys = skip_keys
      builder = self
      mod.module_eval do
        define_singleton_method(:included) do |klass|
          builder.patch_errors_method_on_instance(self, klass)
        end
      end
      mod
    end
  end
end
