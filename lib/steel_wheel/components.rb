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

      def form_params_definition
        @form_params_definition ||= if form_definition.scope
                                      form_definition.params_definition.schema[form_definition.scope].class
                                    else
                                      form_definition.params_definition
                                    end
      end

      def form_definition
        @form_definition ||= Class.new(ActionForm::Rails::Base)
      end

      def url_params(klass = nil, &block)
        self.url_params_definition = Class.new(klass) if klass
        url_params_definition.class_exec(self, &block) if block
      end

      def form(klass = nil, &block)
        self.form_definition = Class.new(klass) if klass
        form_definition.class_eval(&block) if block
      end
    end

    module InstanceMethods # rubocop:disable Style/Documentation
      def url_params
        @url_params ||= self.class.url_params_definition.new(input)
      end

      def form_params
        @form_params ||= self.class.form_params_definition.new(form_input)
      end

      def form(attrs = form_attributes)
        @form ||= self.class.form_definition.new(owner: self, **attrs)
      end

      def form_attributes
        raise SteelWheel::FormAttributesNotImplementedError
      end
    end
  end
end
