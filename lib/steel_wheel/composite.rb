module SteelWheel
  module Composite
    def self.inflector
      ActiveSupport::Inflector
    end

    def self.classify(title)
      inflector.classify(title).to_sym
    end

    def self.singularize(title)
      inflector.singularize(title)
    end

    module DecorationHelpers
      def __sw_composite_define_init__(klass, &init)
        return klass unless block_given?
        klass.singleton_class.send(:define_method, :__sw_init__, &init)
      end

      def __sw_composite_patch_class__(base_class, &block)
        return base_class unless block_given?
        Class.new(base_class, &block)
      end

      def __sw_composite_check_inheritance__!(component_class, base_class)
        return if component_class.nil?
        unless component_class <= base_class
          raise(ArgumentError, "must be a subclass of #{base_class.name}")
        end
      end
    end

    module InheritanceHelpers
      def inherited(subclass)
        subclass.__sw_inheritance_reactivate_composites__
      end

      def __sw_inheritance_reactivate_composites__
        __sw_included_composite_modules__.each do |composite|
          __sw_inheritance_activate_parent_components_of_composite__(composite)
        end
      end

      def __sw_included_composite_modules__
        included_modules.select{|m| m.to_s.match(/SteelWheel::Composite/) }
      end

      def __sw_inheritance_activate_parent_components_of_composite__(composite)
        superclass.public_send("#{composite.components_name}").each do |component, klass|
          public_send(composite.__sw_store_method_name__, component, klass)
        end
      end
    end

    def self.[](components_name)
      return self.const_get(classify(components_name).to_sym) if self.constants.include?(classify(components_name).to_sym)
      mod = Module.new do
        class << self
          attr_accessor :component_name, :components_name

          def included(receiver)
            receiver.extend self
          end

          def extended(receiver)
            receiver.extend DecorationHelpers
            receiver.extend InheritanceHelpers
          end

          def __sw_store_method_name__(title = component_name)
            :"__sw_store_#{title}_class__"
          end

          def __sw_activation_method_name__(title = component_name)
            :"__sw_activate_#{title}_component__"
          end

          def define_component_store_method
            mod = self
            define_method(:"#{mod.__sw_store_method_name__}") do |method_name, klass|
              public_send(:"#{method_name}_#{mod.component_name}_class=", klass)
              public_send(:"#{mod.components_name}")[method_name] = klass
            end
          end

          def define_component_activation_method
            mod = self
            define_method(:"__sw_activate_#{mod.component_name}_component__") do |method_name, base_class, klass, init = nil, &block|
              component_class = public_send(:"#{method_name}_#{mod.component_name}_class") # inherited
              raise(ArgumentError, 'please provide a block or class') if component_class.nil? && klass.nil? && block.nil?

              target_class = component_class || klass || base_class

              __sw_composite_check_inheritance__!(target_class, base_class)

              patched_class = __sw_composite_patch_class__(target_class, &block)
              __sw_composite_define_init__(patched_class, &init)
              public_send(mod.__sw_store_method_name__, method_name, patched_class)
            end
          end

          def define_component_adding_method
            mod = self
            default_init = ->(klass, *attrs) { klass.new }
            define_method(component_name.to_sym) do |method_name, base_class: Class.new, init: default_init|
              __sw_composite_define_init__(base_class, &init)

              singleton_class.class_eval do
                attr_accessor :"#{method_name}_#{mod.component_name}_class"

                define_method method_name do |klass = nil, init: nil, &block|
                  public_send(mod.__sw_activation_method_name__, method_name, base_class, klass, init, &block)
                end
              end
            end
          end

          def define_components_registry
            mod = self
            module_eval <<-METHOD, __FILE__, __LINE__ + 1
              def #{mod.components_name}
                @#{mod.components_name} ||= {}
              end
            METHOD
          end
        end
      end
      const_set(classify(components_name), mod)
      mod.components_name = components_name
      mod.component_name = singularize(components_name)
      mod.define_components_registry
      mod.define_component_adding_method
      mod.define_component_store_method
      mod.define_component_activation_method
      mod
    end
  end
end
