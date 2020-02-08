require 'spec_helper'

RSpec.describe SteelWheel::Rail do
  describe 'railway' do
    context 'when everything is ok' do
      vars do
        operation_class do
          Class.new(SteelWheel::Rail) do
            from :mash
            to :json
            input :mash, base_class: C1 = Class.new(OpenStruct), init: ->(klass, value) { klass.new(value) }
            controller :authorize, base_class: C2 = Class.new(Object)
            controller :sync, base_class: C3 = Class.new(Object)
            controller :store, base_class: C4 = Class.new(Object)
            controller :formatter, base_class: C5 = Class.new(Object)
            mash_input do
              def a
                'a'
              end
            end
            authorize_controller do
              def o
                'o'
              end
            end
            sync_controller do
              def u
                'u'
              end
            end
            store_controller do
              def e
                'e'
              end
            end
            formatter_controller do
              def i
                'i'
              end
            end
            def call
              "#{given.a}#{given.o}#{given.u}#{given.e}y#{given.i}#{given.id}"
            end
          end
        end
        value { { id: 3 } }
      end

      it 'given has access to all nested methods' do
        operation = operation_class.accept(value).prepare
        expect(operation.call).to eq('aoueyi3')
      end
    end

    context 'when something went wrong' do
      vars do
        operation_class do
          Class.new(SteelWheel::Rail) do
            from :mash
            to :json
            input :mash, base_class: X1 = Class.new(OpenStruct), init: ->(klass, values) { klass.new(values) }
            controller :authorize, base_class: X2 = Class.new(Object)
            controller :sync, base_class: X3 = Class.new(Object)
            controller :store, base_class: X4 = Class.new(Object)
            controller :formatter, base_class: X5 = Class.new(Object)
            mash_input do
              def a
                'a'
              end
            end
            authorize_controller do
              include ActiveModel::Validations
              def o
                'o'
              end

              validate do
                errors.add(:base, "Error with id=#{id}") if id == 3
              end
            end
            sync_controller do
              def u
                'u'
              end
            end
            store_controller do
              def e
                'e'
              end
            end
            formatter_controller do
              def i
                'i'
              end
            end
            def call
              "#{given.a}#{given.o}#{given.u}#{given.e}y#{given.i}#{given.id}"
            end
          end
        end
        value { { id: 3 } }
      end

      it 'given has errors' do
        operation = operation_class.accept(value).prepare
        expect(operation.given.errors).to_not be_empty
      end
    end
  end
end
