require 'spec_helper'

RSpec.describe SteelWheel::Cascade do
  vars do
    operation_class do
      Class.new do
        include SteelWheel::Composite[:blocks]
        include SteelWheel::Cascade[:blocks]

        block :adapter
        block :preparator
        block :formatter

        adapter_block {}
        preparator_block do
          def go
            'Go!!!'
          end
        end
        formatter_block {}
      end
    end
    value { { id: 3 } }
  end

  describe 'inheritance' do
    vars do
      child_operation_class do
        Class.new(operation_class) do
          preparator_block do
            def go
              'Stop!!!'
            end
          end
        end
      end
    end

    it 'overrides components' do
      cascade_state = child_operation_class.blocks_cascade_decorating
      expect(cascade_state).to be_a(SteelWheel::CascadingState)
      result = cascade_state.current_object
      expect(result.preparator).to_not be_nil
      expect(result.preparator.adapter).to_not be_nil
      expect(result.preparator.go).to eq('Stop!!!')
    end
  end

  describe '#blocks_cascade_decorating' do
    context 'when everything is ok' do
      it 'returns SteelWheel::CascadingState' do
        cascade_state = operation_class.blocks_cascade_decorating
        expect(cascade_state).to be_a(SteelWheel::CascadingState)
        result = cascade_state.current_object
        expect(result.preparator).to_not be_nil
        expect(result.preparator.adapter).to_not be_nil
        expect(result.preparator.go).to eq('Go!!!')
      end
    end

    context 'when cascade state provided' do
      vars { obj { Object.new } }

      it 'decorates current_object of cascade_state' do
        cascade_state = operation_class.blocks_cascade_decorating(:input, obj)
        expect(cascade_state).to be_a(SteelWheel::CascadingState)
        result = cascade_state.current_object
        expect(result.preparator).to_not be_nil
        expect(result.preparator.adapter).to_not be_nil
        expect(result.preparator.go).to eq('Go!!!')
        expect(result.preparator.adapter.input).to eq(obj)
      end
    end

    context 'when invalid cascade_state provided' do
      it 'raises an error' do
        expect {
          operation_class.blocks_cascade_decorating(nil, Object.new)
        }.to raise_error(ArgumentError, 'Both arguments required')
      end
    end
  end
end
