module SteelWheel
  class Dash < Hash
    def []=(value)
      Class.new do
        attr_reader :dd
        def method_name

        end
      end
    end
  end
end
