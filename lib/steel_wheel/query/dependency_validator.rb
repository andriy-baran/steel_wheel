# frozen_string_literal: true

module SteelWheel
  class Query
    # Presence validation for dependencies
    class DependencyValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if value

        record.errors.add :base, :not_found, message: "#{attribute.to_s.humanize} is missing"
      end
    end
  end
end
