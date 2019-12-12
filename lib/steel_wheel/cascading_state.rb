module SteelWheel
  class CascadingState
    attr_accessor :current_object, :previous_step, :branch

    def initialize(previous_step = nil, current_object = nil)
      @step = 0
      @error_track = false
      @previous_step = previous_step
      @current_object = current_object
    end

    def initial_step?
      previous_step.nil? && current_object.nil?
    end

    def failure
      @error_track = true
    end

    def error_track?
      @error_track
    end
  end
end
