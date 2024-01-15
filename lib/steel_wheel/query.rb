# frozen_string_literal: true

require 'steel_wheel/query/lookup'
require 'steel_wheel/query/dependency_validator'

module SteelWheel
  # Base class for queries
  class Query
    include Memery
    include ActiveModel::Validations

    def self.depends_on(*attrs)
      attr_accessor(*attrs)

      validates(*attrs, 'steel_wheel/query/dependency': true)
    end

    def self.name
      'SteelWheel::Query'
    end

    def lookups
      @lookups ||= {}
    end

    def http_status
      return :ok if errors.empty?
      return errors.keys.first unless defined?(ActiveModel::Error)

      errors.map(&:type).first
    end

    def self.find_one(name, scope = nil, map: { id: :"#{name}_id" }, class_name: nil, required: false)
      define_method(name) do
        search_attrs = map.transform_values { |use| send(use) }
        lookups[__method__] = Lookup.new(__method__, search_attrs, scope, class_name: class_name)
        validate_find_one_presence(__method__, required: required)
      end
      memoize name
      validate name
    end

    def self.find_many(name, scope = nil, map: { id: :"#{name.to_s.singularize}_id" }, class_name: nil)
      define_method(name) do
        search_attrs = map.transform_values { |use| send(use) }
        lookups[__method__] = Lookup.new(__method__, search_attrs, scope, class_name: class_name)
        lookups[__method__].find_many
      end
      memoize name
    end

    private

    def validate_find_one_presence(name, required:)
      lookup = lookups[name]
      record = lookup.find_one
      return unless required && record.nil?

      msg = lookup.default_error_message
      msg = required.fetch(:message, msg) if required.is_a?(Hash)
      errors.add(:base, :not_found, message: msg)
      nil
    end
  end
end
