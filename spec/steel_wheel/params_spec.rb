RSpec.describe SteelWheel::Params do
  vars do
    params_class do
      Class.new(SteelWheel::Params) do
        attribute :id, integer
        attribute :quantity, integer.default(1)
        attribute :sections, array.of(struct) do
          attribute :id, integer
          attribute :content, string.default('')
          attribute :updated_at, date
          attribute :post, struct do
            attribute :id, integer
            attribute :author, string.default('')
            validates :id, presence: { message: "can't be blank" }
          end
          validates :id, presence: { message: "can't be blank" }
        end
        attribute :post, struct do
          attribute :id, integer
          attribute :author, string.default('')
          validates :id, presence: { message: "can't be blank" }
          attribute :sections, array.of(struct) do
            attribute :id, integer
            attribute :content, string.default('')
            attribute :updated_at, date
            attribute :meta, struct do
              attribute :copies, array.of(string)
            end
            validates :id, presence: { message: "can't be blank" }
          end
        end

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

    describe '.to_hash' do
      vars do
        attributes do
          {
            id: 2,
            quantity: 5,
            sections: [
              {
                updated_at: '2018-07-13',
                post: { author: 'Bob'}
              }
            ],
            post: {
              author: 'Bob',
              sections: [
                {
                  updated_at: '2019-07-13',
                  meta: {copies: []}
                },
                {
                  updated_at: '2019-08-13',
                  meta: {copies: []}
                }
              ]
            }
          }
        end
        attributes_with_defaults do
          {
            id: 2,
            quantity: 5,
            sections: [
              {
                content: '',
                id: nil,
                updated_at: Date.parse('2018-07-13'),
                post: { id: nil, author: 'Bob'}
              }
            ],
            post: {
              author: 'Bob',
              id: nil,
              sections: [
                {
                  content: '',
                  id: nil,
                  updated_at: Date.parse('2019-07-13'),
                  meta: {copies: []}
                },
                {
                  content: '',
                  id: nil,
                  updated_at: Date.parse('2019-08-13'),
                  meta: {copies: []}
                }
              ]
            }
          }
        end
      end

      it 'returns hash with correct values' do
        expect(params_obj.to_hash).to eq attributes_with_defaults
      end
    end

    describe '.validate_nested' do
      vars do
        attributes do
          { id: 2, quantity: 5,
            sections: [{updated_at: '2018-07-13', post: { author: 'Bob'}}],
            post: { author: 'Bob', sections: [{updated_at: '2019-07-13'}] }
          }
        end
      end

      it 'returns hash with correct values' do
        params_obj.validate_nested
        expect(OpenStruct.new(params_obj.errors.messages)).to have_attributes(
          :"sections/0/id"=>an_instance_of(Array),
          :"sections/0/post/id"=>an_instance_of(Array),
          :"post/id"=>an_instance_of(Array),
          :"post/sections/0/id"=>an_instance_of(Array)
        )
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
