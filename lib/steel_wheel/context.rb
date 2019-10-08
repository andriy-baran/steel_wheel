module SteelWheel
  class Context < OpenStruct
    include Memery
    include ActiveModel::Validations

    def self.skip_keys(*keys)
      include SteelWheel::SkipActiveModelErrorsKeys[*keys]
    end

    def self.name
      'SteelWheel::Context'
    end

    skip_keys(:not_found, :forbidden, :unprocessable_entity)

    def error_key
      errors.keys.first
    end
  end
end
