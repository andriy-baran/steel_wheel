module SteelWheel
  module Composite
    module InvariableMethods
      def __sw_subclass_error__(base_class)
        -> { raise(ArgumentError, "must be a subclass of #{base_class.name}") }
      end

      def __sw_missing_body_error__
        -> { raise(ArgumentError, 'please provide a block or class') }
      end

      def __sw_add_component_class_accessors__(method_name, component_name)
        singleton_class.class_eval { attr_accessor :"#{method_name}_#{component_name}_class" }
      end
    end
    def self.[](component_name)
      mod = Module.new do
        class << self
          attr_accessor :component_name, :components_name

          def included(receiver)
            receiver.extend self
          end

          def extended(receiver)
            unless receiver.included_modules.include?(SteelWheel::Composite::InvariableMethods)
              receiver.extend SteelWheel::Composite::InvariableMethods
            end
            receiver.__sw_composites__[components_name] = component_name
          end

          def store_method(title = component_name)
            :"__sw_store_#{title}_class__"
          end
        end
      end
      const_set(ActiveSupport::Inflector.classify(component_name), mod)
      mod.component_name = component_name
      mod.components_name = ActiveSupport::Inflector.pluralize(component_name)
      mod.module_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{mod.components_name}
          @#{mod.components_name} ||= {}
        end

        def __sw_composites__
          @@__sw_composites__ ||= {}
        end
      METHOD
      mod.module_eval do
        define_method(:inherited) do |subclass|
          included_modules
            .select{|m| m.to_s.match(/SteelWheel::Composite/)  }
            .each{|composite| subclass.__sw_composites__[composite.components_name] = composite.component_name.to_s}
          subclass.__sw_composites__.each do |(components_name, component_name)|
            public_send("#{components_name}").each do |component, klass|
              store_method = mod.store_method(component_name)
              subclass.public_send(store_method, component, klass)
            end
          end
        end

        define_method(:"__sw_store_#{mod.component_name}_class__") do |method_name, klass|
          public_send(:"#{method_name}_#{mod.component_name}_class=", klass)
          public_send(:"#{mod.components_name}")[method_name] = klass
        end

        define_method(:"__sw_activate_#{mod.component_name}_component__") do |method_name, base_class, klass, &block|
          component_class = public_send(:"#{method_name}_#{mod.component_name}_class")
          if component_class.present? # inherited
            __sw_subclass_error__(base_class).call unless component_class <= base_class

            component_class = Class.new(component_class, &block) if !block.nil?
            public_send(mod.store_method, method_name, component_class)
          elsif klass.present? && block.nil?
            __sw_subclass_error__(base_class).call unless klass <= base_class

            public_send(mod.store_method, method_name, klass)
          elsif klass.nil? && !block.nil?
            component_class = Class.new(base_class, &block)
            public_send(mod.store_method, method_name, component_class)
          else
            __sw_missing_body_error__.call
          end
        end

        define_method(mod.component_name.to_sym) do |method_name, base_class: Class.new|
          __sw_add_component_class_accessors__(method_name, mod.component_name)
          singleton_class.send(:define_method, method_name) do |klass = nil, &block|
            public_send(:"__sw_activate_#{mod.component_name}_component__", method_name, base_class, klass, &block)
          end
        end
      end
      mod
    end
  end
end
