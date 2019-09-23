module SteelWheel
  class Context < OpenStruct
    include Memery
    include ActiveModel::Validations

    require 'steel_wheel/context/active_model_errors/skip_keys'
    include ActiveModelErrors::SkipKeys[:not_found, :forbidden, :unprocessable_entity]

    def self.name
      'SteelWheel::Context'
    end

    def error_key
      errors.keys.first
    end
  end
end
