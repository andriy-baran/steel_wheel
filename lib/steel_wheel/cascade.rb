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

      def __sw_decorate__(previous_step, current_object, instance)
        if previous_step.nil? || current_object.nil?
          instance
        else
          __sw_wrap__(current_object, wrapper_object: instance, accessor: previous_step)
        end
      end

      def __sw_handle_step__(components_group, previous_step, current_object, step, base_class)
        mod_name = "SteelWheel::Composite::#{SteelWheel::Composite.classify(components_group)}"
        mod = self.included_modules.detect {|m| m.to_s == mod_name}
        instance = public_send(mod.__sw_new_instance_method_name__(step))
        __sw_decorate__(previous_step, current_object, instance)
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
            define_method(__sw_cascade_method_name__) do |previous_step = nil, current_object = nil|
              raise(ArgumentError, 'Both arguments required') if previous_step.nil? ^ current_object.nil?
              error_track = false
              public_send(mod.__sw_cascade_components__).each do |step, base_class|
                error_track = true and break if __sw_invalidate_state__(current_object)

                current_object = __sw_handle_step__(mod.__sw_cascade_components__, previous_step, current_object, step, base_class)
                previous_step = step
              end
              SteelWheel::CascadingState.new(previous_step, current_object, error_track)
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
