module SteelWheel
  class Params < Dry::Struct
    include ActiveModel::Validations

    transform_keys(&:to_sym)

    def self.name
      'SteelWheel::Params'
    end

    def validate_array(attr_name)
      public_send(attr_name).each.with_index do |element, i|
        if element.invalid?
          element.errors.each do |error_key,error_message|
            errors.add(:"#{attr_name}[#{i}]_#{error_key}", error_message)
          end
        end
      end
    end
  end
end
