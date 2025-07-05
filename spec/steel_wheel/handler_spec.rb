# frozen_string_literal: true

require 'spec_helper'

class ChildParams < SteelWheel::Params
  integer :id, presence: { message: "can't be blank" }
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

    ok_result do
      {
        errors: [],
        status: :ok
      }
    end

    handler_class do
      Class.new(SteelWheel::Handler) do
        attr_accessor :new_value

        params ChildParams

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
            params do
              integer :id, presence: { message: "can't be blank" }
            end

            def to_h
              { status: http_status, errors: errors.full_messages }
            end
          end
        end
      end

      it 'returns correct result' do
        operation = operation_class.handle(input: {})
        expect(operation.to_h).to eq invalid_params_result
      end
    end

    # context 'when query object is invalid' do
    #   vars do
    #     operation_class do
    #       Class.new(handler_class) do
    #         main_builder.subclass do
    #           query do
    #             validate { errors.add(:base, :not_found, message: 'Query error') }
    #           end
    #         end
    #       end
    #     end
    #   end

    #   it 'returns correct result' do
    #     operation = operation_class.handle(input: {})
    #     expect(operation.to_h).to eq invalid_query_result
    #   end
    # end

    # context 'when command object is invalid' do
    #   vars do
    #     operation_class do
    #       Class.new(handler_class) do
    #         params ChildParams
    #         validate { errors.add(:base, :forbidden, message: 'Command error') }
    #       end
    #     end
    #   end

    #   it 'returns correct result' do
    #     operation = operation_class.handle(input: { id: 1 })
    #     expect(operation.to_h).to eq invalid_command_result
    #   end
    # end

    context 'When all objects are invalid' do
      vars do
        operation_class do
          Class.new(handler_class) do
            params do
              validate { errors.add(:base, :bad_request, message: 'Params error') }
            end
            validate { errors.add(:base, :not_found, message: 'Query error') }
            validate { errors.add(:base, :forbidden, message: 'Command error') }
          end
        end
      end

      it 'returns correct result' do
        operation = operation_class.handle(input: { id: 1 })
        expect(operation.to_h).to eq({ status: :bad_request, errors: ['Params error']  })
      end
    end

    context 'when everything is ok' do
      it 'returns correct result' do
        # expect_any_instance_of(SteelWheel::Handler).to receive(:call)
        operation = handler_class.handle(input: { id: 1 })
        expect(operation.to_h).to eq ok_result
      end
    end

    context 'when context is extended' do
      it 'returns correct result' do
        result = handler_class.handle(input: { id: 1 }) do |i|
          i.new_value = 15
        end
        expect(result.new_value).to eq 15
      end
    end

    context 'when callbacks are provided' do
      it 'returns correct result' do
        result = handler_class.handle(input: { id: 1 }) do |i|
          i.new_value = 15
        end
        expect(result.new_value).to eq 15
      end
    end
  end
end
