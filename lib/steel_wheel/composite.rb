module SteelWheel
  module Composite
    module ClassMethods
      def inherited(subclass)
        controllers.each_key do |controller|
          klass = public_send(:"#{controller}_class")
          subclass.public_send(:"#{controller}_class=", klass)
        end
      end

      def controllers
        @controllers ||= {}
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

      def __sw_activate_controller__(method_name, base_class, klass, &block)
        controller_class = public_send(:"#{method_name}_class")
        if controller_class.present? # inherited
          __sw_subclass_error__(base_class).call unless controller_class <= base_class

          controller_class = Class.new(controller_class, &block) if block_given?
          __sw_store_class__(method_name, controller_class)
        elsif klass.present? && !block_given?
          __sw_subclass_error__(base_class).call unless klass <= base_class

          __sw_store_class__(method_name, klass)
        elsif klass.nil? && block_given?
          controller_class = Class.new(base_class, &block)
          __sw_store_class__(method_name, controller_class)
        else
          __sw_missing_body_error__.call
        end
        controllers[method_name] = controller_class
      end

      def controller(method_name, base_class: Class.new)
        singleton_class.class_eval { attr_accessor :"#{method_name}_class" }
        singleton_class.send(:define_method, method_name) do |klass = nil, &block|
          __sw_activate_controller__(method_name, base_class, klass, &block)
        end
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
    end
  end
end
