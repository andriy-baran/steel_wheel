# frozen_string_literal: true

module SteelWheel
  # Provides precondition validation functionality for handlers
  module Preconditions
    private

    def validate_preconditions
      if url_params.invalid?
        failure_params
      elsif @validate_form && form_params.invalid?
        failure_form
      elsif invalid?
        failure_self
      end
    end

    def failure_params
      self.http_status = url_params.status
      errors.merge!(url_params.errors)
      failure_callback
    end

    def failure_form
      self.http_status = :unprocessable_entity
      @form = form.with_params(form_params)
      failure_callback
    end

    def failure_self
      self.http_status = status
      errors.delete(@form_scope)
      failure_callback
    end
  end
end
