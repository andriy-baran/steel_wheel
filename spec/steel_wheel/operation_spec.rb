require 'spec_helper'

RSpec.describe SteelWheel::Operation do
  describe 'dispatchers' do
    context 'when no errors' do
      vars do
        operation_class do
          Class.new(SteelWheel::Operation) do
            from :mash
            to :json
            controller :formatter
            controller :final
            input :mash, base_class: Z1 = Class.new
            branch :left, base_class: SteelWheel::Rail
            branch :right, base_class: SteelWheel::Rail

            mash_input do
              attr_reader :id
              def initialize(opts = {})
                @id = opts[:id]
              end

              def a
                'a'
              end
            end

            dispatch do |cxt|
              cxt.a == 'a' ? :left : :right
            end

            formatter_controller do
              def i
                'i'
              end
            end

            final_controller do
              def y
                'y'
              end
            end

            left_branch do
              controller :authorize
              controller :sync
              authorize_controller do
                include ActiveModel::Validations
                def o
                  'o'
                end

                validate do
                  errors.add(:base, "Error with id=#{id}") if id == 4
                end
              end

              sync_controller do
                def u
                  'u'
                end
              end
            end

            right_branch do
              controller :store

              store_controller do
                def e
                  'e'
                end
              end
            end

            def call
              "#{given.a}#{given.o}#{given.u}#{given.e}y#{given.i}#{given.id}"
            end
          end
        end
        value { { id: 3 } }
      end

      it 'given has no errors' do
        operation = operation_class.accept(value).prepare
        expect(operation.given.a).to eq 'a'
        expect(operation.given.o).to eq 'o'
        expect(operation.given.u).to eq 'u'
        expect(operation.given.i).to eq 'i'
        expect(operation.given.y).to eq 'y'
        expect do
          operation.given.e
        end.to raise_error(NoMethodError)
      end
    end

    context 'when some errors' do
      vars do
        operation_class do
          Class.new(SteelWheel::Operation) do
            from :mash
            to :json
            controller :formatter
            controller :final
            input :mash, base_class: Z1 = Class.new, init: ->(klass, values) { klass.new(values) }
            branch :left, base_class: SteelWheel::Rail
            branch :right, base_class: SteelWheel::Rail

            mash_input do
              attr_reader :id
              def initialize(opts)
                @id = opts[:id]
              end

              def a
                'a'
              end
            end

            dispatch do |cxt|
              cxt.a == 'a' ? :left : :right
            end

            formatter_controller do
              def i
                'i'
              end
            end

            final_controller do
              def y
                'y'
              end
            end

            left_branch do
              controller :authorize
              controller :sync
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
            end

            right_branch do
              controller :store

              store_controller do
                def e
                  'e'
                end
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
        expect(operation.given.a).to eq 'a'
        expect(operation.given.o).to eq 'o'
        expect {
          operation.given.u
        }.to raise_error(NoMethodError)
        expect {
          operation.given.i
        }.to raise_error(NoMethodError)
        expect {
          operation.given.y
        }.to raise_error(NoMethodError)
        expect {
          operation.given.e
        }.to raise_error(NoMethodError)
      end
    end
  end
end
