module SteelWheel
  class Operation
    def self.inherited(subclass)
      self.controllers.each_key do |controller|
        subclass.public_send(:"#{controller}_class=", self.public_send(:"#{controller}_class"))
      end
    end

    def self.controllers
      @controllers ||= {}
    end

    def self.controller(method_name, base_class: nil)
      self.singleton_class.class_eval { attr_accessor :"#{method_name}_class" }
      self.singleton_class.send(:define_method, method_name) do |klass = nil, &block|
        controller_class = self.public_send(:"#{method_name}_class")
        if controller_class.present? && controller_class <= base_class && block_given? # inherited
          instance_variable_set(:"@#{method_name}_class", Class.new(controller_class, &block))
        else
          if base_class.present?
            if klass.present?
              raise ArgumentError.new("must be a subclass of #{base_class.name}") unless klass <= base_class
              instance_variable_set(:"@#{method_name}_class", klass)
            else
              raise ArgumentError.new('please provide a block') if block_given?
              instance_variable_set(:"@#{method_name}_class", Class.new(base_class, &block))
            end
          else
            if block_given?
              instance_variable_set(:"@#{method_name}_class", Class.new(base_class, &block))
            else
              raise ArgumentError.new('please provide a block') if block_given?
            end
          end
        end
      end
      self.controllers[method_name] = base_class
    end

    def call
      # NOOP
    end
  end
end
