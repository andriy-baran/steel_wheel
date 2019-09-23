module SteelWheel
  class Context
    module ActiveModelErrors
      module SkipKeys
        def self.[](*http_statuses)
          mod = Module.new do
            @http_statuses = http_statuses

            def self.http_statuses
              @http_statuses
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
                          return message if #{http_statuses.inspect}.include?(attribute)
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
  end
end
