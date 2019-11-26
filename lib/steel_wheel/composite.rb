module SteelWheel
  module Composite
    def self.[](component_name)
      mod = Module.new do
        class << self
          attr_accessor :__sw_component_name__, :__sw_components_name__
        end
      end
      const_set(ActiveSupport::Inflector.classify(component_name), mod)
      mod.__sw_component_name__ = component_name
      mod.__sw_components_name__ = ActiveSupport::Inflector.pluralize(component_name)
      mod.module_eval do
        def __sw_subclass_error__(base_class)
          -> { raise(ArgumentError, "must be a subclass of #{base_class.name}") }
        end

        def __sw_missing_body_error__
          -> { raise(ArgumentError, 'please provide a block or class') }
        end

        def __sw_add_component_class_accessors__(method_name)
          singleton_class.class_eval { attr_accessor :"#{method_name}_class" }
        end

        def __sw_activate_component__(method_name, base_class, klass, &block)
          component_class = public_send(:"#{method_name}_class")
          if component_class.present? # inherited
            __sw_subclass_error__(base_class).call unless component_class <= base_class

            component_class = Class.new(component_class, &block) if block_given?
            __sw_store_class__(method_name, component_class)
          elsif klass.present? && !block_given?
            __sw_subclass_error__(base_class).call unless klass <= base_class

            __sw_store_class__(method_name, klass)
          elsif klass.nil? && block_given?
            component_class = Class.new(base_class, &block)
            __sw_store_class__(method_name, component_class)
          else
            __sw_missing_body_error__.call
          end
        end

        define_method(__sw_component_name__.to_sym) do |method_name, base_class: Class.new|
          __sw_add_component_class_accessors__(method_name)
          singleton_class.send(:define_method, method_name) do |klass = nil, &block|
            __sw_activate_component__(method_name, base_class, klass, &block)
          end
        end

        def self.included(receiver)
          receiver.class_eval <<-METHOD, __FILE__, __LINE__ + 1
            def self.#{__sw_components_name__}
              @#{__sw_components_name__} ||= {}
            end

            def self.inherited(subclass)
              #{__sw_components_name__}.each_key do |component|
                klass = public_send(:"\#\{component\}_class")
                subclass.public_send(:"\#\{component\}_class=", klass)
              end
            end

            def self.__sw_store_class__(method_name, klass)
              public_send(:"\#\{method_name\}_class=", klass)
              #{__sw_components_name__}[method_name] = klass
            end
          METHOD
          receiver.extend self
        end
      end
      mod
    end
  end
end
