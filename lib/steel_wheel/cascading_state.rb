module SteelWheel
  class CascadingState
    attr_accessor :current_object, :previous_step

    def initialize(previous_step = nil, current_object = nil, error_track = false)
      @error_track = error_track
      @previous_step = previous_step
      @current_object = current_object
    end

    def error_track?
      @error_track
    end
  end
end
