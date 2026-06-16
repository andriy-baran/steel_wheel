# frozen_string_literal: true

module SteelWheel # rubocop:disable Style/Documentation
  # Rails integration for SteelWheel handlers
  module RailsHelpers
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def action(action_name, handler: action_name, with_handlers: [], &block)
        composed_handlers = Array(with_handlers)

        define_method(action_name) do
          run_action(handler, composed_handlers, &block)
        end
      end
    end

    module InstanceMethods # rubocop:disable Style/Documentation
      def run_action(handler, composed_handlers, &block)
        compose_handler(handler).handle do |primary_handler|
          if composed_handlers.empty?
            instance_exec(primary_handler, &block)
          else
            handlers = [primary_handler, *composed_handlers.map { |name| compose_handler(name) }]
            instance_exec(*handlers, &block)
          end
          failure_callbacks(primary_handler)
        end
      end

      def compose_handler(handler_name, handler_params = params)
        handler_class_for(handler_name).new(handler_params).tap do |handler|
          handler.helpers = view_context
          handler.owner = self
        end
      end

      def handler_class_for(handler)
        different_namespace = handler.to_s.split('/').size > 1
        return "#{handler.to_s.camelize}Handler".constantize if different_namespace

        "#{[params[:controller], handler].compact.join('/')}_handler".classify.constantize
      end

      def failure_callbacks(handler)
        handler.failure(:not_found) do
          render file: Rails.root.join('public', '404.html').to_s, status: handler.http_status
        end
      end
    end
  end
  # Rails integration for SteelWheel handlers
  if defined?(Rails)
    class Railtie < Rails::Railtie # rubocop:disable Style/Documentation
      initializer 'steel_wheel.helpers' do
        ActiveSupport.on_load(:action_controller) do
          ActionController::Base.include RailsHelpers if defined?(ActionController::Base)
          ActionController::API.include RailsHelpers if defined?(ActionController::API)
        end
      end
    end
  end
end
