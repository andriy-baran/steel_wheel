module SteelWheel
  class Query
    include Memery
    include ActiveModel::Validations

    def self.name
      'SteelWheel::Query'
    end

    def http_status
      errors.keys.first
    end
  end
end
