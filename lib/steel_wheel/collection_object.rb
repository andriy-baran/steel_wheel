require "collection_object/version"

module CollectionObject
  def self.[](members)
    mod = Module.new do
      class << self
        attr_accessor :co_members

        def array_methods
          [].public_methods - Enumerable.public_instance_methods - Object.new.public_methods
        end
      end
    end
    mod.co_members = members
    mod.module_eval do
      define_method(:initialize) do |*args, &block|
        instance_variable_set(:"@#{mod.co_members}", [])
      end

      define_method(:each) do |*args, &block|
        return to_enum(:each) if block.nil?

        send(co_members).each(*args, &block)
      end

      def self.included(receiver)
        receiver.send(:include, Enumerable)
        receiver.extend(Forwardable)
        receiver.send(:attr_reader, co_members)
        receiver.def_delegators co_members, *array_methods
      end

      def self.extended(receiver)
        receiver.send(:include, self)
      end
    end
    mod
  end
end
