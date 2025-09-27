# frozen_string_literal: true

require 'ostruct'

class AR
  def self.where(*)
    new
  end

  def first
    nil
  end
end

class Product < AR
  def self.in_stock
    self
  end
end

class User
  class Cart < AR
  end
end

class Variant < AR
  def self.active
    self
  end
end

RSpec.describe SteelWheel::Handler do
  vars do
    query_class do
      Class.new(SteelWheel::Handler) do
        url_params do
          integer :id
          integer :user_id
          integer :cart_id
          array :selected_variant_ids, of: :integer
        end

        depends_on :currency_symbol, validate_provided: { message: 'where is my currency?' }
        depends_on :stock, validate_provided: { allow_nil: true }

        finder :cart, -> { User::Cart.where(id: url_params.cart_id, user_id: url_params.user_id).first }
        finder :product,
               -> { Product.in_stock.where(id: url_params.id).first },
               validate_existence: {
                 base: true,
                 message: -> (object, data) { "Couldn't find Product with 'id'=#{object.url_params.id}" }
               }
        finder :variants, -> { Variant.active.where(id: url_params.selected_variant_ids, product_id: url_params.id) }

      end
    end
  end

  it 'has finders' do
    url_params = { id: 1, user_id: 3465, cart_id: 12, selected_variant_ids: [33, 44] }
    expect(Variant).to receive(:active).and_return(Variant)
    expect(Product).to receive(:in_stock).and_return(Product).twice
    expect(Product).to receive(:where).with(id: 1).and_return([]).twice
    expect(User::Cart).to receive(:where).with(id: 12, user_id: 3465).and_return([])
    expect(Variant).to receive(:where).with(id: [33, 44], product_id: 1)

    query = query_class.handle(url_params)
    query.valid?
    query.product
    query.product
    query.cart
    query.variants
    expect(query.errors.full_messages).to eq ['where is my currency?', "Couldn't find Product with 'id'=1"]
    query = query_class.new(url_params)
    query.currency_symbol = :uah
    query.valid?
    expect(query.errors.full_messages).to eq ["Couldn't find Product with 'id'=1"]
  end
end
