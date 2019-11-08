require 'spec_helper'

RSpec.describe SteelWheel::Operation do
  vars do
    operation_class do
      Class.new(SteelWheel::Operation) do
        def initialize(formatter)
          @formatter = formatter
        end

        controller :parser, base_class: Class.new
        controller :formatter, base_class: Struct.new(:id, keyword_init: true)

        parser do
          def parse(json)
            JSON.parse(json, symbolize_names: true)
          end
        end

        formatter do
          def call
            { id: id, success: true }
          end
        end

        def self.test_instance(json)
          parser = parser_class.new
          formatter = formatter_class.new(parser.parse(json))
          new(formatter)
        end

        def call
          @formatter.call
        end
      end
    end
    value { {id: 3} }
  end

  it { expect(operation_class).to respond_to(:controller) }
  it { expect(operation_class).to respond_to(:parser_class) }
  it { expect(operation_class).to respond_to(:formatter_class) }

  describe 'inheritance' do
    vars do
      child_operation_class do
        Class.new(operation_class) do
          formatter do
            def call
              { id: id, child: true }
            end
          end
        end
      end
    end

    it { expect(child_operation_class).to respond_to(:parser_class) }
    it { expect(child_operation_class).to respond_to(:formatter_class) }

    it 'overrides controllers' do
      operation = child_operation_class.test_instance(value.to_json)
      expect(operation.call).to eq(value.merge(child: true))
    end
  end

  describe '#call' do
    it 'when everything is ok' do
      operation = operation_class.test_instance(value.to_json)
      expect(operation.call).to eq(value.merge(success: true))
    end
  end

  describe 'railway' do
    vars do
      operation_class do
        Class.new(SteelWheel::Operation) do
          controller :mash, base_class: C1 = Class.new(OpenStruct)
          controller :authorize, base_class: C2 = Class.new(OpenStruct)
          controller :sync, base_class: C3 = Class.new(OpenStruct)
          controller :store, base_class: C4 = Class.new(OpenStruct)
          controller :formatter, base_class: C5 = Class.new(OpenStruct)
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
        end
      end
      value { {id: 3} }
    end

    it 'when everything is ok' do
      operation = operation_class.from(value).to(:json).prepare
      expect(operation.success.a).to eq('a')
    end
  end
end
