# frozen_string_literal: true

module SteelWheel
  # Provides filtering functionality for handlers
  module Filters
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def filter(name, &definition)
        define_method("filter_by_#{name}", &definition)
      end

      def filterable(name)
        alias_method :"initial_#{name}_scope", name
        define_method(name) do
          apply_filters(send(:"initial_#{name}_scope"), form_params.to_h)
        end
      end
    end

    module InstanceMethods # rubocop:disable Style/Documentation
      def apply_filters(scope, search_params)
        search_params.each do |key, value|
          scope = send("filter_by_#{key}", scope, value) if value.present?
        end
        scope
      end
    end
  end
end
