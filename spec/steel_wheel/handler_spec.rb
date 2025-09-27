# frozen_string_literal: true

require 'spec_helper'

class ChildParams < SteelWheel::Params
  integer :id, presence: { message: "can't be blank" }
end

class Entity
  include ActiveModel::Validations
  attr_accessor :id

  def initialize(id = nil)
    @id = id
  end

  validates :id, presence: { message: "can't be blank" }
end

RSpec.describe SteelWheel::Handler do
  vars do
    invalid_params_result do
      {
        errors: ['Id can\'t be blank'],
        status: :bad_request
      }
    end

    invalid_query_result do
      {
        errors: ['Query error'],
        status: :not_found
      }
    end

    invalid_command_result do
      {
        errors: ['Command error'],
        status: :forbidden
      }
    end

    invalid_entity_result do
      {
        errors: ['Please provide valid entity id'],
        status: :unprocessable_entity
      }
    end

    ok_result do
      {
        errors: [],
        status: :ok
      }
    end

    handler_class do
      Class.new(SteelWheel::Handler) do
        attr_accessor :new_value

        url_params ChildParams

        def to_h
          { status: http_status, errors: errors.full_messages }
        end

        def call
        end

        def on_validation_success
          call
        end
      end
    end
    title { 'new command' }
    command { OpenStruct.new(title: title) }
  end

  describe '#result' do
    context 'when params object is invalid' do
      vars do
        operation_class do
          Class.new(SteelWheel::Handler) do
            url_params do
              integer :id, presence: { message: "can't be blank" }
              integer :quantity, presence: true, numericality: { greater_than: 0 }
            end

            def entity
              Entity.new
            end

            verify :entity,
                    valid: {
                      base: true,
                      message: {
                        id: -> (o, d) { "Please provide valid entity id" },
                        base: true
                      }
                    }

            def to_h
              { status: http_status, errors: errors.full_messages }
            end

            def call
              to_h
            end
          end
        end
      end

      it 'returns invalid params error' do
        operation = operation_class.handle
        expect(operation.to_h).to eq invalid_params_result
      end

      it 'returns invalid entity error' do
        operation = operation_class.handle({ id: 4 })
        expect(operation.to_h).to eq invalid_entity_result
      end
    end

    context 'When all objects are invalid' do
      vars do
        operation_class do
          Class.new(handler_class) do
            url_params do
              validate { errors.add(:base, :bad_request, message: 'Params error') }
            end
            validate { errors.add(:base, :not_found, message: 'Query error') }
            validate { errors.add(:base, :forbidden, message: 'Command error') }
          end
        end
      end

      it 'returns correct result' do
        operation = operation_class.handle({ id: 1 })
        expect(operation.to_h).to eq({ status: :bad_request, errors: ['Params error']  })
      end
    end

    context 'when everything is ok' do
      it 'returns correct result' do
        operation = handler_class.handle({ id: 1 })
        expect(operation.to_h).to eq ok_result
      end
    end

    context 'when context is extended' do
      it 'returns correct result' do
        result = handler_class.handle({ id: 1 }) do |i|
          i.new_value = 15
        end
        expect(result.new_value).to eq 15
      end
    end

    context 'when callbacks are provided' do
      it 'returns correct result' do
        result = handler_class.handle({ id: 1 }) do |i|
          i.new_value = 15
        end
        expect(result.new_value).to eq 15
      end
    end
  end
end
