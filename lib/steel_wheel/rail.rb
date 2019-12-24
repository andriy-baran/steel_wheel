module SteelWheel
  class Rail
    include SteelWheel::Composite[:controller]
    include SteelWheel::Composite[:input]
    include SteelWheel::Composite[:output]
    include SteelWheel::Cascade[:controllers]

    class Result < OpenStruct; end

    class << self
      attr_accessor :in, :out, :initial_value, :result_attrs
    end

    attr_reader :result, :given

    def initialize(given)
      @given = given
      @result = self.class.__sw_wrap_output__
    end

    def inherited(subclass)
      subclass.from(self.in)
      subclass.to(self.out)
      subclass.result_attrs = result_attrs
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
      inputs[self.in].nil? ? initial_value : inputs[self.in].new(initial_value)
    end

    def self.__sw_wrap_output__
      if outputs[self.out].nil?
        Result.new(result_attrs[self.out])
      else
        outputs[self.out].new(result_attrs[self.out])
      end
    end

    def self.accept(value)
      self.initial_value = value
      self
    end

    def self.result_attrs
      @result_attrs ||= Hash.new { |hash, key| hash[key] = {} }
    end

    def self.result_defaults(input_name, **value)
      self.result_attrs[input_name] = value
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
