# frozen_string_literal: true

module SteelWheel
  # Provides parameter and form components
  module Components
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.singleton_class.attr_writer :params_definition, :form_definition
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def params_definition
        @params_definition ||= Class.new(SteelWheel::Params)
      end

      def form_definition
        @form_definition ||= Class.new(EasyForm::Rails::Base)
      end

      def params(klass = nil, &block)
        self.params_definition = klass if klass
        params_definition.class_exec(self, &block) if block
      end

      def form(klass = nil, &block)
        self.form_definition = klass if klass
        form_definition.class_eval(&block) if block
      end
    end

    module InstanceMethods # rubocop:disable Style/Documentation
      def params
        @params ||= self.class.params_definition.new(input)
      end

      def form_params
        @form_params ||= if @form_scope
                           self.class.form_definition.params_definition.schema[@form_scope].class.new(form_input)
                         else
                           self.class.form_definition.params_definition.new(form_input)
                         end
      end

      def form
        @form ||= self.class.form_definition.new(**form_attributes)
      end
    end
  end
end
