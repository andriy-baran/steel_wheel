# frozen_string_literal: true

module SteelWheel
  # Base class that defines main flow
  class Handler
    # Runs validation on objects
    class Validator
      include ActiveModel::Validations
      attr_accessor :http_status

      def self.run(flow)
        validator = new
        flow.predecessors.reverse_each do |obj|
          break if validator.errors.any?

          validator.validate(obj)
        end
        flow.status = validator.http_status || :ok
        flow.errors.merge!(validator.errors)
      end

      def validate(object)
        return if object.valid?

        self.http_status ||= object.http_status
        errors.merge!(object.errors) if errors.empty?
      end
    end
  end
end
