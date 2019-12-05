module SteelWheel
  class Operation < SteelWheel::Rail
    include SteelWheel::Composite[:branch]

    def self.dispatch(&block)
      klass = Class.new
      klass.send(:define_method, :call, &block)
      controller :"dispatcher#{controllers.size}", base_class: klass
      public_send(:"dispatcher#{controllers.size}") {}
    end

    def self.__sw_handle_step__(cascade, base_class, component)
      if component.match(/dispatcher/)
        dispatcher = base_class.new
        branch_name = dispatcher.call(cascade.current_object)
        cascade.branch = branch_name
        branch_class = branches[branch_name]
        branch_class.singleton_class.class_eval do
          def __sw_resolve_cascade__(cascade)
            new(cascade.current_object)
          end
        end
        branch_class.prepare(cascade)
      else
        super
      end
    end
  end
end
