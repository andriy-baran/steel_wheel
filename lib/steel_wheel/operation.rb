module SteelWheel
  class Operation < SteelWheel::Rail
    include SteelWheel::Composite

    composed_of :branches

    class Result < OpenStruct; end

    def self.dispatch(&block)
      klass = Class.new
      klass.send(:define_method, :call, &block)
      title = :"dispatcher#{controllers.size}"
      controller title, base_class: klass
      public_send("#{title}_controller") {}
    end

    def self.__sw_handle_step__(components_group, previous_step, current_object, component, base_class)
      if component.match(/dispatcher/)
        dispatcher = base_class.new
        branch_name = dispatcher.call(current_object)
        branch_class = branches[branch_name]
        branch_class.singleton_class.class_eval do
          def __sw_resolve_cascade__(cascade)
            cascade.current_object
          end
        end
        branch_class.prepare(previous_step, current_object)
      else
        super
      end
    end
  end
end
