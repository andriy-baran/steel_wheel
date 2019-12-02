module SteelWheel
  class Rail
    include SteelWheel::Composite[:controller]
    include SteelWheel::Cascade[:controllers]

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

    def self.__sw_wrap_input__(klass)
      klass.new(input)
    end

    def self.prepare(cascade = SteelWheel::CascadingState.new)
      controllers_cascade_decorating(cascade)
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
