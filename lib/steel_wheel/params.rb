module SteelWheel
  class Params < Dry::Struct
    include ActiveModel::Validations

    transform_keys(&:to_sym)

    def self.name
      'SteelWheel::Params'
    end

    %w(Integer Decimal Float Bool String Array Date DateTime Time Struct).each do |type|
      self.singleton_class.define_method(type.downcase) { SteelWheel::Types.const_get(type) }
    end

    validate do
      validate_nested
    end

    def validate_nested
      run_nested_validations = proc do |attr_name, value, array_index, error_key_prefix|
        case value
        when Array
          value.each.with_index do |element, i|
            run_nested_validations[attr_name,element,i,error_key_prefix]
          end
        when self.class.struct
          if value.invalid?
            error_key_components = [error_key_prefix, attr_name, array_index]
            attr_error_key_prefix = error_key_components.compact.join('/')
            value.errors.each do |error_key,error_message|
              errors.add("#{attr_error_key_prefix}/#{error_key}", error_message)
            end
          end
          value.attributes.each do |nested_attr_name, nested_value|
            run_nested_validations[nested_attr_name,nested_value,nil,attr_error_key_prefix]
          end
        else
          # NOOP
        end
      end
      attributes.each(&run_nested_validations)
    end
  end
end
