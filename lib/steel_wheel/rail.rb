module SteelWheel
  class Rail
    include SteelWheel::Composite

    class << self
      attr_accessor :input, :output
    end

    attr_reader :result

    def initialize(result)
      @result = result
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
