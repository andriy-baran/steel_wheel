# frozen_string_literal: true

require 'steel_wheel/query/dependency_validator'
require 'steel_wheel/query/verify_validator'
require 'steel_wheel/query/exists_validator'

module SteelWheel
  # Base class for queries
  class Query
    include Memery
    include ActiveModel::Validations

    def self.depends_on(*attrs, provided: false)
      attr_accessor(*attrs)

      validates(*attrs, 'steel_wheel/query/dependency': provided)
    end

    def self.verify(*attrs)
      validates(*attrs, 'steel_wheel/query/verify': true)
    end

    def self.name
      'SteelWheel::Query'
    end

    def http_status
      return :ok if errors.empty?
      return errors.keys.first unless defined?(ActiveModel::Error)

      errors.map(&:type).first
    end

    def self.finder(name, scope, existence: false)
      define_method(name) do
        instance_exec(&scope)
      end
      memoize name
      validates name, 'steel_wheel/query/exists': existence
    end
  end
end
