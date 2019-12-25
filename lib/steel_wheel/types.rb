module SteelWheel
  module Types
    include Dry::Types.module
    Struct    = SteelWheel::Params.meta(omittable: true)
    StructDSL = ::Class.new(SteelWheel::Params).extend(SteelWheel::Params::DSL).meta(omittable: true)
    Integer   = SteelWheel::Types::Params::Integer.optional.meta(omittable: true).default(nil)
    Decimal   = SteelWheel::Types::Params::Decimal.optional.meta(omittable: true).default(nil)
    Float     = SteelWheel::Types::Params::Float.optional.meta(omittable: true).default(nil)
    Bool      = SteelWheel::Types::Strict::Bool.optional.meta(omittable: true).default(nil)
    String    = SteelWheel::Types::String.optional.meta(omittable: true).default(nil)
    Array     = SteelWheel::Types::Array.of(Struct).meta(omittable: true).default([])
    Date      = SteelWheel::Types::Params::Date.optional.meta(omittable: true).default(nil)
    DateTime  = SteelWheel::Types::Params::DateTime.optional.meta(omittable: true).default(nil)
    Time      = SteelWheel::Types::Params::Time.optional.meta(omittable: true).default(nil)
  end
end
