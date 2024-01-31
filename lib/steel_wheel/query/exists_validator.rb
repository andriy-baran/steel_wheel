# frozen_string_literal: true

module SteelWheel
  class Query
    # Presence validation for dependencies
    class ExistsValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return unless value.blank?

        error_key = options[:base] ? :base : attribute
        record.errors.add(error_key, :not_found, message: options.fetch(:message, 'not found'))
      end
    end
  end
end
