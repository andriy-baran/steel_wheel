module SteelWheel
  class Params
    module DSL
      def each(&block)
        array.of(struct, &block)
      end

      def has(&block)
        struct(&block)
      end

      def method_missing(meth, *args, &block)
        if respond_to?(meth)
          super
        else
          public_send(:attribute, meth, *args, &block)
        end
      end
    end
  end
end
