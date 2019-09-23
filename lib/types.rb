module Types
  include Dry::Types.module
  module Optional
    Integer = Types::Params::Integer.optional.meta(omittable: true).default(nil)
    Decimal = Types::Params::Decimal.optional.meta(omittable: true).default(nil)
    Float = Types::Params::Float.optional.meta(omittable: true).default(nil)
    Bool = Types::Strict::Bool.optional.meta(omittable: true).default(nil)
    String = Types::String.optional.meta(omittable: true).default(nil)
    Array = Types::Array.of(SteelWheel::Params).meta(omittable: true).default([])
  end
end
