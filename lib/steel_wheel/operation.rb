module SteelWheel
  class Operation
    def self.inherited(subclass)
      controllers.each_key do |controller|
        klass = public_send(:"#{controller}_class")
        subclass.public_send(:"#{controller}_class=", klass)
      end
    end

    def self.controllers
      @controllers ||= {}
    end

    def self.controller(method_name, base_class: Class.new)
      singleton_class.class_eval { attr_accessor :"#{method_name}_class" }
      singleton_class.send(:define_method, method_name) do |klass = nil, &block|
        controller_class = public_send(:"#{method_name}_class")
        subclass_error_msg = "must be a subclass of #{base_class.name}"
        raise_error = -> { raise(ArgumentError, subclass_error_msg) }
        if controller_class.present? # inherited
          raise_error.call unless controller_class <= base_class

          controller_class = Class.new(controller_class, &block) if block
          instance_variable_set(:"@#{method_name}_class", controller_class)
        elsif klass.present? && block.nil?
          raise_error.call unless klass <= base_class

          instance_variable_set(:"@#{method_name}_class", klass)
        elsif klass.nil? && !block.nil?
          controller_class = Class.new(base_class, &block)
          instance_variable_set(:"@#{method_name}_class", controller_class)
        else
          raise(ArgumentError, 'please provide a block or class')
        end
        controllers[method_name] = controller_class
      end
    end

    def call
      # NOOP
    end
  end
end
