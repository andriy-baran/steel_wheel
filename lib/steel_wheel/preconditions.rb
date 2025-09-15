# frozen_string_literal: true

module SteelWheel
  # Provides precondition validation functionality for handlers
  module Preconditions
    private

    def validate_preconditions(*steps)
      if steps.include?(:params) && params.invalid?
        failure_params
      elsif steps.include?(:form) && form_params.invalid?
        failure_form
      elsif steps.include?(:self) && invalid?
        failure_self
      end
    end

    def failure_params
      self.http_status = params.status
      errors.merge!(params.errors)
      failure_callback
    end

    def failure_form
      self.http_status = :unprocessable_entity
      errors.merge!(form_params.errors)
      @form = form.with_errors(form_params)
      failure_callback
    end

    def failure_self
      self.http_status = status
      failure_callback
    end
  end
end
