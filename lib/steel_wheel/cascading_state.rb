module SteelWheel
  class CascadingState
    attr_accessor :current_object, :wrapped_object, :previous_component, :branch

    def initialize
      @step = 0
    end

    def inc_step
      @step += 1
    end

    def first_step?
      @step.zero?
    end
  end
end
