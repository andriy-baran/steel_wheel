RSpec.describe SteelWheel::Params do
  vars do
    params_class do
      Class.new(SteelWheel::Params) do
        attribute :id, integer
        attribute :quantity, integer.default(1)

        validates :id, :quantity, presence: { message: "can't be blank" }
        validates :quantity, numericality: { only_integer: true, greater_than: 0 }
      end
    end
    attributes { {} }
    params_obj { params_class.new(attributes) }
  end

  it 'is subclass of ActiveModel::Validations' do
    expect(SteelWheel::Params.ancestors).to include(ActiveModel::Validations)
  end

  it 'is subclass of Dry::Struct' do
    expect(SteelWheel::Params.superclass).to eq(Dry::Struct)
  end

  describe '.name' do
    it 'returns SteelWheel::Params' do
      expect(params_class.name).to eq 'SteelWheel::Params'
    end
  end

  context 'public inteface' do
    context 'when validation passes' do
      vars do
        attributes { { id: 2, quantity: 5 } }
      end

      it 'valid? returns true' do
        expect(params_obj).to be_valid
      end
    end

    describe '.attributes' do
      vars do
        attributes { { id: 2, quantity: 5 } }
      end

      it 'returns hash with correct values' do
        expect(params_obj.attributes).to eq attributes
      end
    end

    context 'when validation does not pass' do
      vars do
        messages { ['Id can\'t be blank'] }
      end

      it 'invalid? returns true' do
        expect(params_obj).to be_invalid
      end

      it 'has errors messages' do
        params_obj.invalid?
        expect(params_obj.errors.to_a).to eq messages
      end
    end
  end
end
