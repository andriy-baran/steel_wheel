require 'spec_helper'

RSpec.describe SteelWheel::Rail do
  describe 'railway' do
    context 'when everything is ok' do
      vars do
        operation_class do
          Class.new(SteelWheel::Rail) do
            from :mash
            to :rake
            input :mash, base_class: Class.new(OpenStruct), init: ->(klass, value) { klass.new(value) }
            input :array, base_class: Class.new(OpenStruct), init: ->(klass, value, n1, n2) { klass.new(value.merge(pass: n1, log: n2)) }
            controller :authorize
            output :json, base_class: Class.new(OpenStruct)
            output :rake, base_class: Class.new(OpenStruct)
            array_input do
              def a
                'a'
              end
            end
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
            rake_output do
              def on_success(given)
                self.obj = {
                  a: given.a,
                  o: given.o,
                  id: given.id,
                  pass: given.pass,
                  log: given.log
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
            id: 3,
            pass: 2,
            log: 3
          }
        end
      end

      it 'calls on_success of :json result' do
        operation = operation_class.accept(value).call
        expect(operation.result.obj).to eq rake_result.merge(pass: nil, log: nil)
      end

      it 'calls on_success of :rake result' do
        operation = operation_class.from(:array).accept(value, 2, 3).call
        expect(operation.result.obj).to eq rake_result
      end
    end
  end
end
