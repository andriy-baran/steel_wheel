module SteelWheel
  class Operation < SteelWheel::Rail
    def self.branches
      @branches ||= {}
    end

    def self.dispatch(&block)
      klass = Class.new
      klass.send(:define_method, :call, &block)
      controller :"dispatcher#{controllers.size}", base_class: klass
      public_send(:"dispatcher#{controllers.size}") {}
    end

    def self.branch(branch_name, &block)
      branches[branch_name] = Class.new(SteelWheel::Operation, &block)
    end

    def self.__sw_handle_step__(cascade, base_class, controller, i)
      if controller.match(/dispatcher/)
        dispatcher = base_class.new
        branch_name = dispatcher.call(cascade.current_object)
        cascade.branch = branch_name
        branches[branch_name].prepare(cascade)
      else
        super
      end
    end
  end
end
