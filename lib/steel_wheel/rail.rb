module SteelWheel
  class Rail
    include SteelWheel::Composite[:controllers]
    include SteelWheel::Composite[:inputs]
    include SteelWheel::Composite[:outputs]
    include SteelWheel::Cascade[:controllers]

    class Result < OpenStruct; end

    class << self
      attr_accessor :in, :out, :initial_values
    end

    attr_reader :result, :given

    def initialize(given)
      @given = given
      @result = self.class.__sw_wrap_output__ || Result.new
    end

    def inherited(subclass)
      subclass.from(self.in)
      subclass.to(self.out)
    end

    def self.from(input)
      self.in = input
      self
    end

    def self.to(output)
      self.out = output
      self
    end

    def self.__sw_wrap_input__
      return initial_values if self.in.nil?
      input_class = public_send(:"#{self.in}_input_class")
      return initial_values if input_class.nil?
      public_send(:"new_#{self.in}_input_instance", *initial_values)
    end

    def self.__sw_wrap_output__
      # rescue NoMethodError => ex
      # "You have not define output class. Please add `output :#{self.out}`"
      return if self.out.nil?
      return unless self.respond_to?(:"#{self.out}_output_class")
      output_class = public_send(:"#{self.out}_output_class")
      return if output_class.nil?
      public_send(:"new_#{self.out}_output_instance")
    end

    def self.accept(*values)
      self.initial_values = values
      self
    end

    def self.__sw_resolve_cascade__(cascade)
      new(cascade.current_object).tap do |rail|
        if cascade.error_track?
          __sw_notify_error__(rail, cascade.previous_step)
        else
          __sw_notify_success__(rail)
        end
      end
    end

    def self.__sw_notify_error__(rail, step)
      if rail.result.respond_to?(:"on_#{step}_failure")
        rail.result.public_send(:"on_#{step}_failure", rail.given)
      elsif rail.result.respond_to?(:on_failure)
        rail.result.on_failure(rail.given, step)
      elsif rail.respond_to?(:"on_#{step}_failure")
        rail.public_send(:"on_#{step}_failure")
      else
        rail.on_failure(step)
      end
    end

    def self.__sw_notify_success__(rail)
      if rail.result.respond_to?(:on_success)
        rail.result.on_success(rail.given)
      else
        rail.on_success
      end
    end

    def self.prepare(cascade = SteelWheel::CascadingState.new(self.in, __sw_wrap_input__))
      controllers_cascade_decorating(cascade)
      __sw_resolve_cascade__(cascade)
    end

    class << self
      alias_method :call, :prepare
    end

    def on_failure(failed_step = nil)
      # NOOP
    end

    def on_success
      # NOOP
    end
  end
end
