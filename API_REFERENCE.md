# SteelWheel API Reference

## Classes

### SteelWheel::Handler

Main orchestrator class for the workflow.

#### Class Methods

```ruby
# Define parameters class
params(klass = nil, &block)

# Execute handler
handle(input:, &block)

# Declare dependencies
depends_on(*attrs, provided: false)

# Validate object validity
verify(*attrs)

# Create finder method
finder(name, scope, existence: false)

# Configure generic validation keys (Rails < 6.1)
generic_validation_keys(*keys)
```

#### Instance Methods

```ruby
# Initialize handler
initialize(params)

# Execute workflow
handle(&block)

# Check if successful
success?

# Get HTTP status
status

# Callback hooks
on_validation_success
on_validation_failure
```

#### Instance Variables

```ruby
@params       # Parameters object
@http_status  # Current HTTP status (default: :ok)
```

### SteelWheel::Params

Base class for parameter handling (extends EasyParams::Base).

#### Methods

```ruby
# Get status based on errors
status  # Returns :ok or :bad_request
```

## Custom Validators

### SteelWheel::Query::DependencyValidator

```ruby
validates :attribute, 'steel_wheel/query/dependency': true
validates :attribute, 'steel_wheel/query/dependency': { message: "Custom message" }
```

### SteelWheel::Query::ExistsValidator

```ruby
validates :attribute, 'steel_wheel/query/exists': true
validates :attribute, 'steel_wheel/query/exists': { base: true }
```

### SteelWheel::Query::VerifyValidator

```ruby
validates :attribute, 'steel_wheel/query/verify': true
```

## Error Handling

### HTTP Status Codes

- `:ok` - Success
- `:bad_request` - Parameter validation errors
- `:unauthorized` - Authentication errors
- `:forbidden` - Authorization errors
- `:not_found` - Resource not found errors
- `:unprocessable_entity` - Business logic errors

### Error Methods

```ruby
# Add errors with status codes
errors.add(:base, :not_found, "Resource not found")          # Rails 6.1+
errors.add(:not_found, "Resource not found")                 # Rails < 6.1

# Check status
handler.status    # Returns status symbol
handler.success?  # Returns boolean
```

## Generator Commands

```bash
# Generate application handler
rails generate steel_wheel:application_handler

# Generate specific handler
rails generate steel_wheel:handler namespace/action

# Generate params class
rails generate steel_wheel:params namespace/action

# Generate scaffold controller
rails generate steel_wheel:scaffold_controller ModelName
```

## Usage Examples

### Basic Handler

```ruby
class MyHandler < SteelWheel::Handler
  params do
    attribute :name, string
    validates :name, presence: true
  end
  
  depends_on :current_user
  
  def on_validation_success
    # Your logic here
  end
end
```

### Separate Components

```ruby
class MyHandler < SteelWheel::Handler
  class Params < SteelWheel::Params
    attribute :name, string
    validates :name, presence: true
  end
  
  class Query < SteelWheel::Query
    depends_on :current_user
    finder :record, -> { Model.find_by(id: params.id) }
  end
  
  class Command < SteelWheel::Command
    def call
      # Business logic
    end
  end
  
  params Params
  query Query
  command Command
end
```

### Controller Integration

```ruby
class MyController < ApplicationController
  def create
    result = MyHandler.handle(input: params.to_unsafe_h) do |handler|
      handler.current_user = current_user
    end
    
    if result.success?
      redirect_to root_path, notice: 'Success!'
    else
      render :new, status: result.status
    end
  end
end
```

## Dependencies

- `railties` (>= 3.2, < 8)
- `easy_params` (~> 0.5)
- `memery` (~> 1)
- `nina` (~> 0.2)

## Version

Current version: 0.6.1