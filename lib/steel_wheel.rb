# frozen_string_literal: true

require 'easy_params'
require 'active_model'
require 'memery'
require 'action_form'
require 'steel_wheel/skip_active_model_errors_keys'
require 'steel_wheel/params'
require 'steel_wheel/filters'
require 'steel_wheel/preconditions'
require 'steel_wheel/callbacks'
require 'steel_wheel/components'
require 'steel_wheel/shortcuts'
require 'steel_wheel/handler'
require 'steel_wheel/railtie'
require 'steel_wheel/version'

module SteelWheel
  class Error < StandardError; end
  class ActionNotImplementedError < Error; end

  class FilterNotImplementedError < Error # rubocop:disable Style/Documentation
    def initialize(filter_name)
      super(<<~HEREDOC)
        Filter #{filter_name} is not implemented

        Example:
        filter :#{filter_name} do |scope, value|
          scope.where(#{filter_name}: value)
        end

      HEREDOC
    end
  end

  class FormAttributesNotImplementedError < Error # rubocop:disable Style/Documentation
    def initialize
      super(<<~HEREDOC)
        Subclass must implement form_attributes which returns a hash of attributes for the form

        Example:
        def form_attributes
          { model: model }
        end
      HEREDOC
    end
  end
end
