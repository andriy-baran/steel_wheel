module SteelWheel
  module Cascade
    module MethodMissingDecoration
      def method_missing(name, *attrs, &block)
        if public_send(__sw_predecessor__)
          public_send(__sw_predecessor__).public_send(name, *attrs, &block)
        else
          super
        end
      end

      def respond_to_missing?(_method_name, _include_private = false)
        !public_send(__sw_predecessor__).nil?
      end
    end

    module Helpers
      def __sw_wrap__(current_object, wrapper_object:, accessor:)
        wrapper_object.singleton_class.class_eval do
          attr_accessor :__sw_predecessor__
        end
        wrapper_object.__sw_predecessor__ = accessor
        wrapper_object.extend(SteelWheel::Cascade::MethodMissingDecoration)
        wrapper_object.singleton_class.class_eval do
          attr_accessor wrapper_object.__sw_predecessor__
        end
        wrapper_object.public_send(:"#{wrapper_object.__sw_predecessor__}=", current_object)
        wrapper_object
      end

      def __sw_invalidate_state__(o)
        o.class.ancestors.include?(ActiveModel::Validations) && o.invalid?
      end

      def __sw_decorate__(cascade, instance)
        if cascade.initial_step?
          cascade.current_object = instance
        else
          cascade.current_object = __sw_wrap__(
            cascade.current_object,
            wrapper_object: instance,
            accessor: cascade.previous_step)
        end
      end

      def __sw_handle_step__(components_group, cascade, base_class, step)
        mod_name = "SteelWheel::Composite::#{SteelWheel::Composite.classify(components_group)}"
        mod = self.included_modules.detect {|m| m.to_s == mod_name}
        instance = public_send(mod.__sw_new_instance_method_name__(step))
        __sw_decorate__(cascade, instance)
        cascade.previous_step = step
      end
    end

    def self.[](components)
      mod = Module.new do
        class << self
          attr_accessor :__sw_cascade_components__

          def included(receiver)
            receiver.extend self
          end

          def extended(receiver)
            receiver.extend Helpers
          end

          def __sw_cascade_method_name__
            :"#{__sw_cascade_components__}_cascade_decorating"
          end

          def define_cascade_decorating_method
            mod = self
            define_method(__sw_cascade_method_name__) do |cascade = SteelWheel::CascadingState.new|
              raise(ArgumentError, "must be a subclass of SteelWheel::CascadingState") unless cascade.class <= SteelWheel::CascadingState
              public_send(mod.__sw_cascade_components__).each do |step, base_class|
                cascade.failure and break if __sw_invalidate_state__(cascade.current_object)

                __sw_handle_step__(mod.__sw_cascade_components__, cascade, base_class, step)
              end
              cascade
            end
          end
        end
      end
      mod.__sw_cascade_components__ = components
      mod.define_cascade_decorating_method
      mod
    end
  end
end
