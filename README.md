# SteelWheel
[![Maintainability](https://api.codeclimate.com/v1/badges/a197758aa1cfde54f0e1/maintainability)](https://codeclimate.com/github/andriy-baran/steel_wheel/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a197758aa1cfde54f0e1/test_coverage)](https://codeclimate.com/github/andriy-baran/steel_wheel/test_coverage)
[![Gem Version](https://badge.fury.io/rb/steel_wheel.svg)](https://badge.fury.io/rb/steel_wheel)

The library is a tool for building highly structured service objects.

## Concepts

### Stages
We may consider any controller action as a sequence of following stages:
1. **Input validations and preparations**
* Describe the structure of parameters
* Validate values, provide defaults
2. **Querying data and preparing context**
* Records lookups by IDs in parameters
* Validate permissions to perform an action
* Validate conditions (business logic requirements)
* Inject Dependencies
* Set up current user
3. **Performing Action (skipped on GET requests)**
* Updade database state
* Enqueue jobs
* Handle exceptions
* Validate intermediate states
4. **Exposing Results/Errors**
* Presenters
* Contextual information useful for the users

### Implementation of stages
As you can see each step has specific tasks and can be implemented as a separate object.

**SteelWheel::Params (gem https://github.com/andriy-baran/easy_params)**
* provides DSL for `params` structure definition
* provides type coercion and default values for individual attributes
* has ActionModel::Validation included
* implements `http_status` method that returs HTTP error code

**SteelWheel::Query**
* has `Memery` module included
* has ActionModel::Validation included
* implements `http_status` method that returs HTTP error code

**SteelWheel::Command**
* has ActionModel::Validation included
* implements `http_status` method that returs HTTP error code
* implements `call` method that should do the stuff

**SteelWheel::Response**
* has ActionModel::Validation included
* implements `status` method that returs HTTP error code
* implements `success?` method that checks if there are any errors

### Process
Let's image the process that connects stages described above
* Get an input and initialize object for params, run validations, trigger callbacks
* Initialize object for preparing context and give it an access to previous object, run validation, trigger callbacks
* Initialize object for performing action and give it an access to previous object, run validation, trigger callbacks
* Initialize resulting object and give it an access to previous object, run action, copy errors, trigger callbacks
* If everything is ok run action and handle errors that appear during execution time.
* If we have an error on any stage we stop validating new objects in a queue, just creating them to get instance methods they provide.

### Callbacks

`on_params_created(params)` calls `invalid?` and triggers `on_params_success(params)` or `on_params_failure(params)` respectively.

`on_query_created(query)` calls `invalid?` and triggers `on_query_success(query)` or `on_query_failure(query)` respectively. But it omits them if there were errors detected on previous stage.

`on_command_created(command)` calls `invalid?` and triggers `on_command_success(command)` or `on_command_failure(command)` respectively. But it omits them if there were errors detected on previous stages.

`on_complete(flow)` calls `success?` and triggers `on_success(flow)` or `on_failure(flow)` respectively.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'steel_wheel'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install steel_wheel

## Usage

Add base handler

```bash
bin/rails g steel_wheel:application_handler
```

Add specific handler

```bash
bin/rails g steel_wheel:handler products/create
```
This will generate `app/handlers/products/create.rb`. And we can customize it

```ruby
class Products::CreateHandler < ApplicationHandler
  define do
    params do
      attribute :title, string
      attribute :weight, string
      attribute :price, string

      validates :title, :weight, :price, presence: true
      validates :weight, allow_blank: true, format: { with: /\A[0-9]+\s[g|kg]\z/ }
    end

    query do
      validate :product, :variant

      memoize def new_product
        Product.new(title: title)
      end

      memoize def new_variant
        new_product.build_variant(weight: weight, price: price)
      end

      private

      def product
        errors.add(:base, :unprocessable_entity, new_product.errors.full_messages.join("\n")) if new_product.invalid?
      end

      def variant
        errors.add(:base, :unprocessable_entity, new_variant.errors.full_messages.join("\n")) if new_variant.invalid?
      end
    end

    command do
      def add_to_stock!
        PointOfSale.find_each do |pos|
          PosProductStock.create!(pos_id: pos.id, product_id: new_product.id, on_hand: 0.0)
        end
      end

      def call(response)
        ::ApplicationRecord.transaction do
          new_product.save!
          new_variant.save!
          add_to_stock!
        rescue => e
          response.errors.add(:unprocessable_entity, e.message)
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  def on_success(flow)
    flow.call
  end
end
```
Looks too long. Lets move code into separate files.
```bash
bin/rails g steel_wheel:query products/create
```
Add relative code
```ruby
# Base class also can be refered via
# ApplicationHandler.main_builder.abstract_factory.params_factory.base_class
class Products::CreateParams < SteelWheel::Params
  attribute :title, string
  attribute :weight, string
  attribute :price, string

  validates :title, :weight, :price, presence: true
  validates :weight, allow_blank: true, format: { with: /\A[0-9]+\s[g|kg]\z/ }
end
```
Than do the same for query
```bash
bin/rails g steel_wheel:query products/create
```
Add code...
```ruby
# Base class also can be refered via
# ApplicationHandler.main_builder.abstract_factory.query_factory.base_class
class Products::CreateQuery < SteelWheel::Query
  validate :product, :variant

  memoize def new_product
    Product.new(title: title)
  end

  memoize def new_variant
    new_product.build_variant(weight: weight, price: price)
  end

  private

  def product
    errors.add(:unprocessable_entity, new_product.errors.full_messages.join("\n")) if new_product.invalid?
  end

  def variant
    errors.add(:unprocessable_entity, new_variant.errors.full_messages.join("\n")) if new_variant.invalid?
  end
end
```
And finally command
```bash
bin/rails g steel_wheel:command products/create
```
Move code
```ruby
class Manage::Products::CreateCommand < SteelWheel::Command
  def add_to_stock!
    ::PointOfSale.find_each do |pos|
      ::PosProductStock.create!(pos_id: pos.id, product_id: new_product.id, on_hand: 0.0)
    end
  end

  def call(response)
    ::ApplicationRecord.transaction do
      new_product.save!
      new_variant.save!
      add_to_stock!
    rescue => e
      response.errors.add(:unprocessable_entity, e.message)
      raise ActiveRecord::Rollback
    end
  end
end
```
Than we can update handler
```ruby
# app/handlers/manage/products/create_handler.rb
class Manage::Products::CreateHandler < ApplicationHandler
  define do
    params Manage::Products::CreateParams

    query Manage::Products::CreateQuery

    command Manage::Products::CreateCommand
  end

  def on_success(flow)
    flow.call(flow)
  end
end
```

### HTTP status codes and errors handling

It's important to provide a correct HTTP status when we faced some problem(s) during request handling. The library encourages developers to add the status codes when they add errors.
```ruby
errors.add(:unprocessable_entity, 'error')
```
As you know `full_messages` will produce `['Unprocessable Entity error']` to prevent this and get only error `SteelWheel::Response` has special method that makes some error keys to behave like `:base`
```ruby
# Default setup
generic_validation_keys(:not_found, :forbidden, :unprocessable_entity, :bad_request, :unauthorized)
# To override it in your app
class SomeHandler
  define do
    response do
      generic_validation_keys(:not_found, :forbidden, :unprocessable_entity, :bad_request, :unauthorized, :payment_required)
    end
  end
end
```
In Rails 6.1 `ActiveModel::Error` was introdused and previous setup is not needed, second argument is used instead
```ruby
errors.add(:base, :unprocessable_entity, 'error')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andriy-baran/steel_wheel. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SteelWheel project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andriy-baran/steel_wheel/blob/master/CODE_OF_CONDUCT.md).
