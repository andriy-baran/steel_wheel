# frozen_string_literal: true

module SteelWheel
  # Rails integration for SteelWheel handlers
  if defined?(Rails)
    class Railtie < Rails::Railtie
      module Helpers # rubocop:disable Style/Documentation
        def self.included(base)
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end

        module ClassMethods # rubocop:disable Style/Documentation
          def action(action_name, class_name: nil, handler: action_name, act: nil, &block)
            define_method(action_name) do
              handler_klass = handler_class_for(class_name, handler)
              handler_klass.handle(act, params) do |handler_instance|
                handler_instance.helpers = view_context
                instance_exec(handler_instance, &block)
                failure_callbacks(handler_instance)
              end
            end
          end
        end

        module InstanceMethods # rubocop:disable Style/Documentation
          def handler_class_for(class_name, action_name = params[:action])
            return class_name.constantize if class_name

            "#{[params[:controller], action_name].compact.join('/')}_handler".classify.constantize
          end

          def failure_callbacks(handler)
            handler.failure(:not_found) do
              render file: Rails.root.join('public', '404.html').to_s, status: handler.http_status
            end
          end
        end
      end

      initializer 'steel_wheel.helpers' do
        ActiveSupport.on_load(:action_controller) do
          ActionController::Base.include Helpers if defined?(ActionController::Base)
          ActionController::API.include Helpers if defined?(ActionController::API)
        end
      end
    end
  end
end
