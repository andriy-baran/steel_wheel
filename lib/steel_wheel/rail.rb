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
        outputs[self.class.out].new(result_attrs[self.out])
      end
    end

    def self.accept(value)
      self.initial_value = value
      self
    end

    def self.result_attrs
      @result_attrs ||= {}
    end

    def self.result_defaults(input_name, **value)
      self.result_attrs[input_name] = value
      self
    end

    def self.__sw_resolve_cascade__(cascade)
      new(cascade.current_object).tap do |op|
        if cascade.error_track?
          if op.respond_to?(:"on_#{cascade.previous_step}_failure")
            op.public_send(:"on_#{cascade.previous_step}_failure")
          else
            op.on_failure(cascade.previous_step)
          end
        else
          op.on_success
        end
      end
    end

    def self.prepare(cascade = SteelWheel::CascadingState.new)
      if cascade.first_step?
        cascade.previous_step = self.in
        cascade.current_object = __sw_wrap_input__
        cascade.inc_step
      end
      controllers_cascade_decorating(cascade)
      __sw_resolve_cascade__(cascade)
    end

    def on_failure(failed_step = nil)
      # NOOP
    end

    def on_success
      # NOOP
    end
  end
end
