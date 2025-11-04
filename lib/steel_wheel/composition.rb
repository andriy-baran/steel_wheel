# frozen_string_literal: true

module SteelWheel
  # Provides host–guest association helpers for ActionForm components.
  # When included, it exposes `host_object` and `host_association_name` accessors
  # and delegates `host_*` method calls to the associated host via `method_missing`.
  module Composition
    def self.included(base)
      base.attr_accessor :owner
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def part_of(owner_name)
        @owner_name = owner_name
        alias_method owner_name, :owner
      end
    end

    module InstanceMethods # rubocop:disable Style/Documentation
      def method_missing(name, *attrs, **kwargs, &block)
        return super unless name.to_s.start_with?('owner_')

        owner_method = name.to_s.sub('owner_', '').to_sym
        return super unless (handler = owners_chain.detect { |o| o.respond_to?(owner_method) })

        handler.public_send(owner_method, *attrs, **kwargs, &block)
      end

      def respond_to_missing?(method_name, include_private = false)
        return super unless method_name.to_s.start_with?('owner_')

        owners_chain.any? { |o| o.respond_to?(method_name.to_s.sub('owner_', '').to_sym, include_private) }
      end

      private

      def owners_chain
        @owners_chain ||= Enumerator.new do |y|
          obj = self
          y << obj = obj.owner while obj.respond_to?(:owner)
        end.lazy
      end
    end
  end
end
