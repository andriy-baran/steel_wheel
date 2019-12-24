require 'spec_helper'

RSpec.describe SteelWheel::Rail do
  describe 'railway' do
    context 'when everything is ok' do
      vars do
        operation_class do
          Class.new(SteelWheel::Rail) do
            from :mash
            to :json
            input :mash, base_class: Class.new(OpenStruct)
            controller :authorize, base_class: Class.new(Object)
            controller :sync, base_class: Class.new(Object)
            controller :store, base_class: Class.new(Object)
            controller :formatter, base_class: Class.new(Object)
            output :json, base_class: OpenStruct
            output :rake, base_class: OpenStruct
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
            json do
              def on_success(given)
                self.string = "#{given.a}#{given.o}#{given.u}#{given.e}y#{given.i}#{given.id}"
              end
            end
            rake do
              def on_success(given)
                self.obj = {
                  a: given.a,
                  o: given.o,
                  u: given.u,
                  e: given.e,
                  i: given.i,
                  id: given.id
                }
              end
            end

            def on_success
              result.string = "#{given.a}#{given.o}#{given.u}#{given.e}y#{given.i}#{given.id}"
            end
          end
        end
        value { { id: 3 } }
        rake_result do
          {
            a: 'a',
            o: 'o',
            u: 'u',
            e: 'e',
            i: 'i',
            id: 3
          }
        end
      end

      it 'calls on_success of :json result' do
        operation = operation_class.accept(value).call
        expect(operation.result.string).to eq('aoueyi3')
      end

      it 'calls on_success of :rake result' do
        operation = operation_class.to(:rake).accept(value).call
        expect(operation.result.obj).to eq rake_result
      end
    end

    context 'when something went wrong' do
      vars do
        operation_class do
          Class.new(SteelWheel::Rail) do
            from :mash
            to :json
            input :mash, base_class: Class.new(OpenStruct)
            controller :authorize, base_class: Class.new(Object)
            controller :sync, base_class: Class.new(Object)
            controller :store, base_class: Class.new(Object)
            controller :formatter, base_class: Class.new(Object)
            output :json, base_class: OpenStruct
            output :rake, base_class: OpenStruct
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
            json do
              def on_authorize_failure(given)
                self.error = given.errors.full_messages.join
              end
            end
            rake do
              def on_failure(given, step)
                self.error = given.errors.full_messages.join
                self.step = step
              end
            end

            def on_authorize_failure
              result.errors = given.errors.full_messages.join
            end
          end
        end
        value { { id: 3 } }
      end

      it 'calls on_authorize_failure of :json result' do
        operation = operation_class.accept(value).call
        expect(operation.result.error).to eq('Error with id=3')
      end

      it 'calls on_failure of :rake result' do
        operation = operation_class.to(:rake).accept(value).call
        expect(operation.result).to have_attributes(step: :authorize, error:'Error with id=3')
      end
    end
  end
end