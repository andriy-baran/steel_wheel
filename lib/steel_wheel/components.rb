# frozen_string_literal: true

module SteelWheel
  # Provides parameter and form components
  module Components
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.singleton_class.attr_writer :url_params_definition, :form_definition
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def url_params_definition
        @url_params_definition ||= Class.new(SteelWheel::Params)
      end

      def form_definition
        @form_definition ||= Class.new(EasyForm::Rails::Base)
      end

      def url_params(klass = nil, &block)
        self.url_params_definition = klass if klass
        url_params_definition.class_exec(self, &block) if block
      end

      def form(klass = nil, &block)
        self.form_definition = klass if klass
        form_definition.class_eval(&block) if block
      end
    end

    module InstanceMethods # rubocop:disable Style/Documentation
      def url_params
        @url_params ||= self.class.url_params_definition.new(input)
      end

      def form_params
        @form_params ||= if @form_scope
                           self.class.form_definition.params_definition.schema[@form_scope].class.new(form_input)
                         else
                           self.class.form_definition.params_definition.new(form_input)
                         end
      end

      def form(attrs = form_attributes)
        @form ||= self.class.form_definition.new(**attrs)
      end

      def form_attributes
        raise SteelWheel::FormAttributesNotImplementedError
      end
    end
  end
end
