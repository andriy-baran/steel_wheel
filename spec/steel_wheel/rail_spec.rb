require 'spec_helper'

RSpec.describe SteelWheel::Rail do
  describe 'railway' do
    context 'when everything is ok' do
      vars do
        operation_class do
          Class.new(SteelWheel::Rail) do
            controller :mash, base_class: C1 = Class.new(OpenStruct)
            controller :authorize, base_class: C2 = Class.new(Object)
            controller :sync, base_class: C3 = Class.new(Object)
            controller :store, base_class: C4 = Class.new(Object)
            controller :formatter, base_class: C5 = Class.new(Object)
            mash do
              def a
                'a'
              end
            end
            authorize do
              def o
                'o'
              end
            end
            sync do
              def u
                'u'
              end
            end
            store do
              def e
                'e'
              end
            end
            formatter do
              def i
                'i'
              end
            end
            def call
              "#{result.a}#{result.o}#{result.u}#{result.e}y#{result.i}#{result.id}"
            end
          end
        end
        value { { id: 3 } }
      end

      it 'result has access to all nested methods' do
        operation = operation_class.from(value).to(:json).prepare
        expect(operation.call).to eq('aoueyi3')
      end
    end

    context 'when something went wrong' do
      vars do
        operation_class do
          Class.new(SteelWheel::Rail) do
            controller :mash, base_class: X1 = Class.new(OpenStruct)
            controller :authorize, base_class: X2 = Class.new(Object)
            controller :sync, base_class: X3 = Class.new(Object)
            controller :store, base_class: X4 = Class.new(Object)
            controller :formatter, base_class: X5 = Class.new(Object)
            mash do
              def a
                'a'
              end
            end
            authorize do
              include ActiveModel::Validations
              def o
                'o'
              end

              validate do
                errors.add(:base, "Error with id=#{id}") if id == 3
              end
            end
            sync do
              def u
                'u'
              end
            end
            store do
              def e
                'e'
              end
            end
            formatter do
              def i
                'i'
              end
            end
            def call
              "#{result.a}#{result.o}#{result.u}#{result.e}y#{result.i}#{result.id}"
            end
          end
        end
        value { { id: 3 } }
      end

      it 'result has errors' do
        operation = operation_class.from(value).to(:json).prepare
        expect(operation.result.errors).to_not be_empty
      end
    end
  end
end
