module SteelWheel
  module SkipActiveModelErrorsKeys
    def self.[](*skip_keys)
      mod = Module.new do
        class << self
          attr_accessor :skip_keys

          def extended(klass)
            klass.include self
          end
        end
      end
      mod.skip_keys = skip_keys
      mod.module_eval do
        def self.included(klass)
          mod = self
          klass.singleton_class.class_eval do
            alias_method :__new__, :new

            define_method :new do |*args|
              __new__(*args).tap do |instance|
                instance.errors.singleton_class.class_eval do
                  define_method :full_message do |attribute, message|
                    return message if mod.skip_keys.include?(attribute)
                    super(attribute, message)
                  end
                end
              end
            end
          end
        end
      end
      mod
    end
  end
end
