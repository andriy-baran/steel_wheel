# frozen_string_literal: true

module SteelWheel
  class Query
    # Verify validation for objects
    class VerifyValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if value.nil?
        return if value.valid?

        value.errors.each do |error|
          error_key = options[:base] ? :base : attribute
          message = options.fetch(:message).fetch(error.attribute.to_sym, "#{error.attribute} #{error.message}")
          record.errors.add(error_key, :unprocessable_entity, message: message)
        end
      end
    end
  end
end
