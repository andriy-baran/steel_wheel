# frozen_string_literal: true

module SteelWheel
  # Provides shortcuts methods for handlers
  module Shortcuts
    def self.included(base)
      base.extend(self)
    end

    def depends_on(*attrs, validate_provided: true)
      attr_accessor(*attrs)

      validates(*attrs, 'steel_wheel/query/dependency': validate_provided)
    end

    def verify(*attrs, valid: true)
      validates(*attrs, 'steel_wheel/query/verify': valid)
    end

    def finder(name, scope, validate_existence: false)
      define_method(name) do
        instance_exec(&scope)
      end
      memoize name
      validates name, 'steel_wheel/query/exists': validate_existence
    end
  end
end
