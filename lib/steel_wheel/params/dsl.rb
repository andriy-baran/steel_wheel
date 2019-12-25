module SteelWheel
  class Params
    module DSL
      def each(&block)
        array.of(struct_dsl, &block)
      end

      def has(&block)
        struct_dsl(&block)
      end

      def method_missing(method_name, *args, &block)
        if respond_to?(method_name)
          super
        else
          public_send(:attribute, method_name, *args, &block)
        end
      end
    end
  end
end
