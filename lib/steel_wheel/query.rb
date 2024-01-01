# frozen_string_literal: true

module SteelWheel
  # Base class for queries
  class Query
    include Memery
    include ActiveModel::Validations

    def self.name
      'SteelWheel::Query'
    end

    def http_status
      return :ok if errors.empty?
      return errors.keys.first unless defined?(ActiveModel::Error)

      errors.map(&:type).first
    end

    def self.find_one(name, scope = nil, map: { id: :"#{name}_id" }, class_name: nil)
      relation = (class_name || name.to_s.camelize).constantize
      relation.instance_exec(&scope) if scope
      memoize define_method(name) { relation.where(**map.transform_values { |use| send(use) }).first }
    end

    def self.find_many(name, scope = nil, map: { id: :"#{name.to_s.singularize}_id" }, class_name: nil)
      relation = (class_name || name.to_s.singularize.camelize).constantize
      relation.instance_exec(&scope) if scope
      memoize define_method(name) { relation.where(**map.transform_values { |use| send(use) }) }
    end
  end
end
