module SteelWheel
  class CascadingState
    attr_accessor :current_object, :wrapped_object, :previous_controller, :type

    def initialize
      @type = :main
    end

    def main?
      type == :main
    end

    def branch?
      type == :branch
    end
  end
end
