module SteelWheel
  module SkipActiveModelErrorsKeys
    def self.[](*skip_keys)
      mod = Module.new do
        @skip_keys = skip_keys

        def self.skip_keys
          @skip_keys
        end
      end
      mod.module_eval do
        def self.included(klass)
          klass.class_eval %Q{
            class << klass
              alias_method :_new, :new

              def new(*args)
                _new(*args).tap do |instance|
                  class << instance.errors
                    def full_message(attribute, message)
                      return message if #{skip_keys.inspect}.include?(attribute)
                      super
                    end
                  end
                end
              end
            end
          }
        end
      end
      mod
    end
  end
end
