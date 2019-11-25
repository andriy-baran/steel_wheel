module SteelWheel
  class Rail
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

    attr_reader :result

    def initialize(result)
      @result = result
    end

    def self.__sw_subclass_error__(base_class)
      -> { raise(ArgumentError, "must be a subclass of #{base_class.name}") }
    end

    def self.__sw_missing_body_error__
      -> { raise(ArgumentError, 'please provide a block or class') }
    end

    def self.__sw_store_class__(method_name, klass)
      instance_variable_set(:"@#{method_name}_class", klass)
    end

    def self.__sw_activate_controller__(method_name, base_class, klass, &block)
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

    def self.controller(method_name, base_class: Class.new)
      singleton_class.class_eval { attr_accessor :"#{method_name}_class" }
      singleton_class.send(:define_method, method_name) do |klass = nil, &block|
        __sw_activate_controller__(method_name, base_class, klass, &block)
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

    def self.__sw_decoration_module__
      Module.new do
        def method_missing(name, *attrs, &block)
          if public_send(__sw_predecessor__)
            public_send(__sw_predecessor__).public_send(name, *attrs, &block)
          else
            super
          end
        end

        def respond_to_missing?(_method_name, _include_private = false)
          !public_send(__sw_predecessor__).nil?
        end
      end
    end

    def self.__sw_wrap__(current_object, wrapper_object:, accessor:)
      wrapper_object.singleton_class.class_eval do
        attr_accessor :__sw_predecessor__
      end
      wrapper_object.__sw_predecessor__ = accessor
      wrapper_object.extend(__sw_decoration_module__)
      wrapper_object.singleton_class.class_eval do
        attr_accessor wrapper_object.__sw_predecessor__
      end
      wrapper_object.public_send(:"#{wrapper_object.__sw_predecessor__}=", current_object)
      wrapper_object
    end

    def self.__sw_invalidate_state__(o)
      o.class.ancestors.include?(ActiveModel::Validations) && o.invalid?
    end

    def self.__sw_wrap_input__(klass)
      klass.new(input)
    end

    def self.__sw_decorate__(cascade, base_class, _i)
      if cascade.first_step?
        cascade.current_object = __sw_wrap_input__(base_class)
      else
        cascade.wrapped_object = __sw_wrap__(cascade.current_object,
                                             wrapper_object: base_class.new,
                                             accessor: cascade.previous_controller)
        cascade.current_object = cascade.wrapped_object
      end
    end

    def self.__sw_handle_step__(cascade, base_class, controller, i)
      __sw_decorate__(cascade, base_class, i)
      cascade.previous_controller = controller
      cascade.inc_step
    end

    def self.__sw_cascade_decorating__(cascade)
      lambda do |(controller, base_class), i|
        break if __sw_invalidate_state__(cascade.wrapped_object)

        __sw_handle_step__(cascade, base_class, controller, i)
      end
    end

    def self.prepare(cascade = SteelWheel::CascadingState.new)
      controllers.each.with_index(&__sw_cascade_decorating__(cascade))
      new(cascade.current_object)
    end

    def success?
      result.respond_to?(:errors) &&
        result.errors &&
        result.errors.any?
    end

    def failure?
      !success?
    end

    def call
      # NOOP
    end
  end
end
