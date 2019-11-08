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

    class << self
      attr_accessor :input, :output
    end

    attr_reader :success, :failure

    def initialize(success, failure)
      @success = success
      @failure = failure
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

    def self.from(input)
      self.input = input
      self
    end

    def self.to(output)
      self.output = output
      self
    end

    def self.prepare
      obj = nil
      old_controller = nil
      decorator_obj = nil
      controllers.each.with_index do |(controller, base_class), i|
        if i.zero?
          obj = base_class.new(input)
        else
          base_class.singleton_class.class_eval do
            attr_accessor :__predecessor__
          end
          decorator_obj = base_class.new
          decorator_obj.__predecessor__ = old_controller
          decorator_obj.instance_eval do
            def method_missing(name, *attrs, &block)
              if public_send(__predecessor__)
                public_send(__predecessor__).public_send(name, *attrs, &block)
              else
                super
              end
            end

            def respond_to_missing?
              !public_send(__predecessor__).nil?
            end
          end
          decorator_obj.singleton_class.class_eval do
            attr_accessor decorator_obj.__predecessor__
          end
          decorator_obj.public_send(:"#{decorator_obj.__predecessor__}=", obj)
          obj = decorator_obj
        end
        old_controller = controller
      end
      new(decorator_obj, nil)
    end

    def call
      # NOOP
    end
  end
end
