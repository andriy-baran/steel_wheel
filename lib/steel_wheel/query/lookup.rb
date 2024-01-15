# frozen_string_literal: true

module SteelWheel
  class Query
    # Utility class for generation simplest ActiveRecord queries
    class Lookup
      def initialize(name, search_attrs, scope = nil, class_name: nil)
        @search_attrs = search_attrs
        @relation = (class_name || name.to_s.singularize.camelize).constantize
        @relation.instance_exec(&scope) if scope
      end

      def find_one
        @relation.where(**@search_attrs).first
      end

      def find_many
        @relation.where(**@search_attrs)
      end

      def default_error_message
        "Couldn't find #{@relation.name} with #{@search_attrs.map { |k, v| "'#{k}'=#{v}" }.join(', ')}"
      end
    end
  end
end
