module SteelWheel
  module Composite
    def self.[](component_name)
      mod = Module.new do
        class << self
          attr_accessor :__sw_component_name__, :__sw_components_name__

          def included(receiver)
            receiver.extend self
          end

          def extended(receiver)
            receiver.__sw_composites__[__sw_components_name__] = __sw_component_name__
          end
        end
      end
      const_set(ActiveSupport::Inflector.classify(component_name), mod)
      mod.__sw_component_name__ = component_name
      mod.__sw_components_name__ = ActiveSupport::Inflector.pluralize(component_name)
      mod.module_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{mod.__sw_components_name__}
          @#{mod.__sw_components_name__} ||= {}
        end

        def __sw_composites__
          @@__sw_composites__ ||= {}
        end
      METHOD
      mod.module_eval do
        define_method(:inherited) do |subclass|
          included_modules
            .select{|m| m.to_s.match(/SteelWheel::Composite/)  }
            .each{|composite| subclass.__sw_composites__[composite.__sw_components_name__] = composite.__sw_component_name__.to_s}
          subclass.__sw_composites__.each do |(components_name, component_name)|
            public_send("#{components_name}").each do |component, klass|
              store_method = :"__sw_store_#{component_name}_class__"
              subclass.public_send(store_method, component, klass)
            end
          end
        end

        define_method(:"__sw_store_#{mod.__sw_component_name__}_class__") do |method_name, klass|
          public_send(:"#{method_name}_#{mod.__sw_component_name__}_class=", klass)
          public_send(:"#{mod.__sw_components_name__}")[method_name] = klass
        end

        def __sw_subclass_error__(base_class)
          -> { raise(ArgumentError, "must be a subclass of #{base_class.name}") }
        end

        def __sw_missing_body_error__
          -> { raise(ArgumentError, 'please provide a block or class') }
        end

        def __sw_add_component_class_accessors__(method_name, component_name)
          singleton_class.class_eval { attr_accessor :"#{method_name}_#{component_name}_class" }
        end

        define_method(:"__sw_activate_#{mod.__sw_component_name__}_component__") do |method_name, base_class, klass, &block|
          component_class = public_send(:"#{method_name}_#{mod.__sw_component_name__}_class")
          store_method = :"__sw_store_#{mod.__sw_component_name__}_class__"
          if component_class.present? # inherited
            __sw_subclass_error__(base_class).call unless component_class <= base_class

            component_class = Class.new(component_class, &block) if !block.nil?
            public_send(store_method, method_name, component_class)
          elsif klass.present? && block.nil?
            __sw_subclass_error__(base_class).call unless klass <= base_class

            public_send(store_method, method_name, klass)
          elsif klass.nil? && !block.nil?
            component_class = Class.new(base_class, &block)
            public_send(store_method, method_name, component_class)
          else
            __sw_missing_body_error__.call
          end
        end

        define_method(mod.__sw_component_name__.to_sym) do |method_name, base_class: Class.new|
          __sw_add_component_class_accessors__(method_name, mod.__sw_component_name__)
          singleton_class.send(:define_method, method_name) do |klass = nil, &block|
            public_send(:"__sw_activate_#{mod.__sw_component_name__}_component__", method_name, base_class, klass, &block)
          end
        end
      end
      mod
    end
  end
end
