# frozen_string_literal: true
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

RSpec.describe SteelWheel::Query do
  vars do
    query_class do
      Class.new(SteelWheel::Query) do
        find_one :cart, map: { id: :cart_id, user_id: :user_id }, class_name: 'User::Cart'
        find_one :product, -> { in_stock }, map: { id: :id }
        find_many :variants, -> { active }, map: { id: :selected_variant_ids, product_id: :id }
      end
    end
  end

  it 'has finders' do
    params = OpenStruct.new(id: 1, user_id: 3465, cart_id: 12, selected_variant_ids: [33, 44] )
    expect(Variant).to receive(:active)
    expect(Product).to receive(:in_stock)
    expect(Product).to receive(:where).with(id: 1).and_return([])
    expect(User::Cart).to receive(:where).with(id: 12, user_id: 3465).and_return([])
    expect(Variant).to receive(:where).with(id: [33, 44], product_id: 1)

    query = query_class.new
    Nina.def_accessor(:params, on: query, to: params, delegate: true)
    query.product
    query.product
    query.cart
    query.variants
  end
end
