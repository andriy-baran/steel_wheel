module SteelWheel
  class CascadingState
    attr_accessor :current_object, :wrapped_object, :previous_step, :branch

    def initialize
      @step = 0
      @error_track = false
    end

    def inc_step
      @step += 1
    end

    def first_step?
      @step.zero?
    end

    def failure
      @error_track = true
    end

    def error_track?
      @error_track
    end
  end
end
