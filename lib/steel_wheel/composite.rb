module SteelWheel
  module Composite
    module ClassMethods
      def inherited(subclass)
        components.each_key do |component|
          klass = public_send(:"#{component}_class")
          subclass.public_send(:"#{component}_class=", klass)
        end
      end

      def components
        @components ||= {}
      end

      def __sw_subclass_error__(base_class)
        -> { raise(ArgumentError, "must be a subclass of #{base_class.name}") }
      end

      def __sw_missing_body_error__
        -> { raise(ArgumentError, 'please provide a block or class') }
      end

      def __sw_store_class__(method_name, klass)
        instance_variable_set(:"@#{method_name}_class", klass)
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
        components[method_name] = component_class
      end

      def component(method_name, base_class: Class.new)
        singleton_class.class_eval { attr_accessor :"#{method_name}_class" }
        singleton_class.send(:define_method, method_name) do |klass = nil, &block|
          __sw_activate_component__(method_name, base_class, klass, &block)
        end
      end
    end

    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end
