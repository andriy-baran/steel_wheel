module SteelWheel
  class Rail
    include SteelWheel::Composite[:controller]

    module MethodMissingDecoration
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

    class << self
      attr_accessor :input, :output
    end

    attr_reader :result, :given

    def initialize(given)
      @given = given
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

    def self.__sw_wrap__(current_object, wrapper_object:, accessor:)
      wrapper_object.singleton_class.class_eval do
        attr_accessor :__sw_predecessor__
      end
      wrapper_object.__sw_predecessor__ = accessor
      wrapper_object.extend(MethodMissingDecoration)
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

    def self.__sw_decorate__(cascade, base_class)
      if cascade.first_step?
        cascade.current_object = __sw_wrap_input__(base_class)
      else
        cascade.wrapped_object = __sw_wrap__(cascade.current_object,
                                             wrapper_object: base_class.new,
                                             accessor: cascade.previous_controller)
        cascade.current_object = cascade.wrapped_object
      end
    end

    def self.__sw_handle_step__(cascade, base_class, controller)
      __sw_decorate__(cascade, base_class)
      cascade.previous_controller = controller
      cascade.inc_step
    end

    def self.__sw_cascade_decorating__(cascade)
      controllers.each do |controller, base_class|
        __sw_component_inactive_error__(controller).call if base_class.nil?
        cascade.failure and break if __sw_invalidate_state__(cascade.current_object)

        __sw_handle_step__(cascade, base_class, controller)
      end
    end

    def self.prepare(cascade = SteelWheel::CascadingState.new)
      __sw_cascade_decorating__(cascade)
      new(cascade.current_object).tap do |op|
        cascade.error_track? ? op.on_failure(cascade.previous_controller) : op.on_success
      end
    end

    def on_failure(failed_step = nil)
      # NOOP
    end

    def on_success
      # NOOP
    end
  end
end
