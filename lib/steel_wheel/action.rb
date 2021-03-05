module SteelWheel
  class Action
    include Memery
    include ActiveModel::Validations

    def self.skip_validation_keys(*keys)
      include SteelWheel::SkipActiveModelErrorsKeys[*keys]
    end

    def self.name
      'SteelWheel::Action'
    end

    skip_validation_keys(:not_found, :forbidden, :unprocessable_entity)

    def error_key
      errors.keys.first
    end
  end
end
