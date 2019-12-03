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

    module InvariableMethods
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

      def __sw_decorate__(cascade, base_class)
        cascade.wrapped_object =
          __sw_wrap__(cascade.current_object,
                      wrapper_object: base_class.new,
                      accessor: cascade.previous_controller)
        cascade.current_object = cascade.wrapped_object
      end

      def __sw_handle_step__(cascade, base_class, controller)
        __sw_decorate__(cascade, base_class)
        cascade.previous_controller = controller
        cascade.inc_step
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
            unless receiver.included_modules.include?(SteelWheel::Cascade::InvariableMethods)
              receiver.extend SteelWheel::Cascade::InvariableMethods
            end
          end
        end
      end
      mod.__sw_cascade_components__ = components
      mod.module_eval do
        define_method(:"#{mod.__sw_cascade_components__}_cascade_decorating") do |cascade|
          public_send(mod.__sw_cascade_components__).each do |controller, base_class|
            __sw_component_inactive_error__(controller).call if base_class.nil?
            cascade.failure and break if __sw_invalidate_state__(cascade.current_object)

            __sw_handle_step__(cascade, base_class, controller)
          end
        end
      end
      mod
    end
  end
end
