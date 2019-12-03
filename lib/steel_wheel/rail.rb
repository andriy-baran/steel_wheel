module SteelWheel
  class Rail
    include SteelWheel::Composite[:controller]
    include SteelWheel::Composite[:input]
    include SteelWheel::Composite[:output]
    include SteelWheel::Cascade[:controllers]

    class << self
      attr_accessor :in, :out, :initial_value
    end

    attr_reader :result, :given

    def initialize(given)
      @given = given
      @result = result
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

    def self.accept(value)
      self.initial_value = value
      self
    end

    def self.__sw_resolve_cascade__(cascade)
      new(cascade.current_object).tap do |op|
        cascade.error_track? ? op.on_failure(cascade.previous_controller) : op.on_success
      end
    end

    def self.prepare(cascade = SteelWheel::CascadingState.new)
      if cascade.first_step?
        cascade.previous_controller = self.in
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
