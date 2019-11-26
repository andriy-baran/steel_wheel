module SteelWheel
  module Composite
    def self.[](component_name)
      mod = Module.new do
        class << self
          attr_accessor :__sw_component_name__, :__sw_components_name__

          def included(receiver)
            receiver.extend self
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
      METHOD
      mod.module_eval do
        define_method(:inherited) do |subclass|
          public_send("#{mod.__sw_components_name__}").each_key do |component|
            klass = public_send(:"#{component}_class")
            subclass.public_send(:"#{component}_class=", klass)
          end
          # included_modules
          #   .select{|m| m.to_s.match(/SteelWheel::Composite/) && !subclass.included_modules.include?(m) }
          #   .each{|composite| subclass.send(:include, composite)}
        end

        define_method(:"__sw_store_#{mod.__sw_component_name__}_class__") do |method_name, klass|
          public_send(:"#{method_name}_class=", klass)
          public_send(:"#{mod.__sw_components_name__}")[method_name] = klass
        end

        def __sw_subclass_error__(base_class)
          -> { raise(ArgumentError, "must be a subclass of #{base_class.name}") }
        end

        def __sw_missing_body_error__
          -> { raise(ArgumentError, 'please provide a block or class') }
        end

        def __sw_add_component_class_accessors__(method_name)
          singleton_class.class_eval { attr_accessor :"#{method_name}_class" }
        end

        define_method(:"__sw_activate_#{mod.__sw_component_name__}_component__") do |method_name, base_class, klass, &block|
          component_class = public_send(:"#{method_name}_class")
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
          __sw_add_component_class_accessors__(method_name)
          singleton_class.send(:define_method, method_name) do |klass = nil, &block|
            public_send(:"__sw_activate_#{mod.__sw_component_name__}_component__", method_name, base_class, klass, &block)
          end
        end
      end
      mod
    end
  end
end
