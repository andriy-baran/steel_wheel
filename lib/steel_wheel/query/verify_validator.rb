# frozen_string_literal: true

module SteelWheel
  class Query
    # Presence validation for dependencies
    class VerifyValidator < ActiveModel::EachValidator
      def validate_each(record, _attribute, value)
        return if value.nil?

        record.errors.merge!(value.errors) if value.invalid?
      end
    end
  end
end
