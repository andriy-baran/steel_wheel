module SteelWheel
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
  end
end
