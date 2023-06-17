# frozen_string_literal: true

module SteelWheel
  # Allows to treat some error codes as :base
  #   EX:
  #   generic_validation_keys :not_found
  #   errors.add(:not_found, 'Can not find')
  #   errors.full_messages => ['Can not find']
  #   not ['Not found an not find']
  module SkipActiveModelErrorsKeys
    def self.build_module
      Module.new do
        class << self
          attr_accessor :skip_keys

          def extended(klass)
            klass.include self
          end
        end
      end
    end

    # rubocop:disable Metrics/MethodLength
    def self.patch_errors_method_on_instance(mod, klass)
      class << klass
        alias_method :__new__, :new
      end

      klass.define_singleton_method :new do |*args|
        instance = __new__(*args)
        instance.errors.define_singleton_method :full_message do |attribute, message|
          return message if mod.skip_keys.include?(attribute)

          super(attribute, message)
        end
        instance
      end
    end
    # rubocop:enable Metrics/MethodLength

    def self.[](*skip_keys)
      mod = build_module
      mod.skip_keys = skip_keys
      builder = self
      mod.module_eval do
        define_singleton_method(:included) do |klass|
          builder.patch_errors_method_on_instance(self, klass)
        end
      end
      mod
    end
  end
end
