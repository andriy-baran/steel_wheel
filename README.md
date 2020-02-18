# SteelWheel

## Intention
The gem is intended to provide better development experience for rails developers

## Solution
Introduce the new layer that provides enchanced programming interface. The new abstractions and flows helps developers focus on domain code and forget about framework details.

## Design Concepts

### Typical data flow in web apps
![](https://github.com/andriy-baran/steel_wheel/blob/master/assets/action_diagram.png?raw=true)
1. **Input validations and preparations**
* describe structure of parameters
* validate values
* save values via models
2. **Preparing context**
* Records lookups by IDs in parameters
* Checking for permissions to perform action
* Checking for conditions (business logic requirements)
* Inject Dependencies
3. **Performing Action**
4. **Exposing Results**

Each of this phase should have a separate object for solving only its specific tasks.

### Cascade decoration
It's a very simple concept to understand if you imagine Russian nesting doll. So the smallest doll will represent initial step/object and next one will on one hand wrap initial doll and delegate appropriate methods to it and on the other hand will add more methods (decorator pattern), and so on... until we reach the last object. Every step will expand functionality and enrich data so it works as cascade. The result object will responce to any method defined on any object in the cascade. If cascade allows different strategies for nesting it's called **Controlled cascade**

The cascade implements the rail-way programing techinque in OO fashion, but instead of functions we have objects that able to validate their state. It means that every object in cascade is validated before continue next step of nesting. If errors happen cascade stops execution and calls appropriate errors handler. See further

![](https://github.com/andriy-baran/steel_wheel/blob/master/assets/cascade_decoration.png?raw=true)

### Cell pattern
It's composition of objects is inspired by biological cells. Each cell has many inputs, many outputs and many internal routes that connect prevous two. If we put this on first diagrams, than parameters is a kind of input, json string is a kind of output, Context and Action are internal routes. Controlled cascade is used for implementing "object decoration routing"
![](https://github.com/andriy-baran/steel_wheel/blob/master/assets/flow_diagram.png?raw=true)

## Implementation

### SteelWheel::Params
This class of ojects handles `params` validations and type coercion, based on `dry-types` and `dry-struct`

```ruby
# app/params/api/v2/icqa/move_params.rb
class Api::V2::Icqa::MoveParams < SteelWheel::Params
  attribute :receive_cart_id, integer
  attribute :i_am_sure, bool
  attribute :location_code, string.default('')
  attribute :sections, struct do
    attribute :from, string
    attribute :to, string
  end
  attribute :options, array.of(struct) do
    attribute :option_type_count, integer
    attribute :option_type_value, integer

    validates :option_type_count, :option_type_value, presence: { message: "can't be blank" }
  end

  validates :receive_cart_id, :location_code, presence: { message: "can't be blank" }
end
```
Validation messages for nested attributes will look like this.
```ruby
{
  :"sections/0/id"=>an_instance_of(Array),
  :"sections/0/post/id"=>an_instance_of(Array),
  :"post/id"=>an_instance_of(Array),
  :"post/sections/0/id"=>an_instance_of(Array)
 }
```

### SteelWheel::Context
This class of objects validates contexts and do any queries to database or 3rd party services.
```ruby
# app/contexts/api/v2/icqa/move_context.rb
class Api::V2::Icqa::MoveContext < SteelWheel::Context
  # Supports memoization
  memoize def receive_cart
    ReceiveCart.where(id: receive_cart_id).first
  end

  # Supports http status codes :not_found, :forbidden, :unprocessable_entity
  validate do
    errors.add(:not_found, "Couldn't find ReceiveCart with id=#{receive_cart_id}") if receive_cart.nil?
    errors.add(:forbidden, "Not allowed") if receive_cart && user.cannot?(:edit, receive_cart)
  end
end
```


### SteelWheel::Action
Nothing special just wrapper arond context. Should have at least one method, preferable `call`
```ruby
# app/actions/api/v2/icqa/move_action.rb
class Api::V2::Icqa::MoveAction < SteelWheel::Action
  def call
    receive_cart.move(from, to, user)
  end
end
```

### SteelWheel::Rail
This class is responsible for execution of cascade decorating. By design it implements cell pattern and owns result object. Any input is a first step of the cascade. Also this object does errors handling, by implementing a chain of responsibility pattern.
```ruby
Class.new(SteelWheel::Rail) do
  input :mash, base_class: Class.new(OpenStruct)
  controller :authorize
  output :json, base_class: Class.new(OpenStruct)
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
  json_output do
    def on_authorize_failure(given) # Priority 1
      self.error = given.errors.full_messages.join
    end

    def on_failure(given, step)     # Priority 2
      self.string = [given.a, given.o].to_json
    end
  end

  def on_authorize_failure          # Priority 3
    result.errors = given.errors.full_messages.join
  end

  def on_failure(given, step)       # Priority 4
    result.errors = given.errors.full_messages.join
  end
end
```
In addition it calls action and update result with properly formatted data. See Usage section

### SteelWheel::Operation
It's a successor of `SteelWheel::Rail` with only difference: it implements `controlled cascade`
```ruby
Class.new(SteelWheel::Operation) do
  controller :final
  input :mash, base_class: Z1 = Class.new
  branch :left, base_class: SteelWheel::Rail
  branch :right, base_class: SteelWheel::Rail

  mash_input do
    def a
      'a'
    end
  end

  dispatch do |cxt|
    cxt.a == 'a' ? :left : :right
  end

  final_controller do
    def y
      'y'
    end
  end

  left_branch do
    controller :authorize
    authorize_controller do
      def o
        'o'
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
    "#{given.a}#{given.o}#{given.y}"
  end
end
```

## Usage
At the moment library is most suitable for JSON APIs.
### Create base operation
```ruby
# app/operations/api_json_operation.rb
class ApiJsonOperation < SteelWheel::Operation
  include SteelWheel::Flows::ApiJson
end
```
### Develop first operation
```ruby
# app/operations/api/v2/icqa/move_operation.rb
class Api::V2::Icqa::MoveOperation < ApiJsonOperation
  params do
    # SteelWheel::Params
  end
  # OR params Api::V2::Icqa::MoveParams

  context do
    # SteelWheel::Context
  end
  # OR context Api::V2::Icqa::MoveContext

  action do
    # SteelWheel::Action
  end
  # OR action Api::V2::Icqa::MoveAction

  def on_failure
    object = given.errors
    result.text = object.to_json
  end

  def on_success
    object = given.call
    result.text = object.to_json
  end
end
```
### Insert operation in controller
```ruby
class Api::V2::IcqaController < Api::V2::ApplicationController
  def move
    op = Api::V2::Icqa::MoveOperation.from_params(params) do |ctx|
      ctx.user = current_api_user # Extend operation context
    end
    op.call
    render op.result.to_h
  end
end
```
### Rake tasks
TBD

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'steel_wheel'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install steel_wheel

## We promise
In the future it will allow to make unit testing fully isolated from database.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andriy-baran/steel_wheel. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SteelWheel project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andriy-baran/steel_wheel/blob/master/CODE_OF_CONDUCT.md).
