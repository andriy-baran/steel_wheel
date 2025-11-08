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
        @form_params_definition ||= form_definition.params_definition
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
        @form ||= create_form(attrs)
      end

      private

      def create_form(attrs)
        if form_input.present?
          create_form_from_form_params
        else
          create_form_from_definition(attrs)
        end
      end

      def create_form_from_definition(attrs)
        self.class.form_definition.new(owner: self, **attrs)
      end

      def create_form_from_form_params
        form_params&.create_form(owner: self, method: owner_request.request_method, action: owner_request.path)
      end

      def form_attributes
        raise SteelWheel::FormAttributesNotImplementedError
      end
    end
  end
end
