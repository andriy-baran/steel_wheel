# frozen_string_literal: true

module SteelWheel
  class Query
    # Verify validation for objects
    class VerifyValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if value.nil? || value.valid?

        value.errors.each { |error| add_error_to_record(record, attribute, error) }
      end

      private

      def add_error_to_record(record, attribute, error)
        error_key = options[:base] ? :base : attribute
        message = build_error_message(error)
        record.errors.add(error_key, :unprocessable_entity, message: message)
      end

      def build_error_message(error)
        if options[:message]
          options.fetch(:message).fetch(error.attribute.to_sym, "#{error.attribute} #{error.message}")
        else
          "#{error.attribute} #{error.message}"
        end
      end
    end
  end
end
