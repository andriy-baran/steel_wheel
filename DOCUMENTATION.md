# SteelWheel Library Documentation

## Overview

**SteelWheel** is a Ruby gem that provides a structured approach to building service objects for Rails applications. It implements a multi-stage pattern that separates concerns into distinct phases: parameter validation, data querying, command execution, and response handling.

**Version:** 0.6.1
**License:** MIT
**Author:** Andrii Baran
**GitHub:** https://github.com/andriy-baran/steel_wheel

## Architecture

The library follows a four-stage pattern:

1. **Params Stage** - Input validation and parameter processing
2. **Query Stage** - Data fetching and context preparation  
3. **Command Stage** - Business logic execution
4. **Response Stage** - Result formatting and error handling

## Core Classes

### SteelWheel::Handler

The main orchestrator class that manages the entire workflow.

#### Class Methods

##### `params(klass = nil, &block)`
Defines the parameters class for the handler.

```ruby
# Using a class
params ProductParams

# Using a block
params do
  attribute :name, string
  validates :name, presence: true
end
```

##### `handle(input:, &block)`
Class method to create and execute a handler instance.

```ruby
result = MyHandler.handle(input: { name: "Product" }) do |handler|
  handler.current_user = current_user
end
```

##### `depends_on(*attrs, provided: false)`
Declares dependencies that must be provided to the handler.

```ruby
depends_on :current_user, :organization
```

##### `verify(*attrs)`
Validates that specified attributes are valid objects.

```ruby
verify :product, :user
```

##### `finder(name, scope, existence: false)`
Creates a memoized finder method with optional existence validation.

```ruby
finder :product, -> { Product.find_by(id: params.product_id) }, existence: true
```

#### Instance Methods

##### `initialize(params)`
Creates a new handler instance with the given parameters.

##### `handle(&block)`
Executes the handler workflow, calling validation and callback methods.

##### `success?`
Returns true if there are no errors.

##### `status`
Returns the HTTP status symbol (`:ok`, `:bad_request`, etc.).

##### `on_validation_failure`
Callback method called when validation fails. Override in subclasses.

##### `on_validation_success`
Callback method called when validation succeeds. Override in subclasses.

#### Instance Variables

- `@params` - The parameters object
- `@http_status` - Current HTTP status (defaults to `:ok`)

### SteelWheel::Params

Base class for parameter handling, extends `EasyParams::Base`.

#### Methods

##### `status`
Returns `:bad_request` if there are errors, `:ok` otherwise.

```ruby
class ProductParams < SteelWheel::Params
  attribute :name, string
  attribute :price, float
  
  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
end
```

## Custom Validators

### SteelWheel::Query::DependencyValidator

Validates that dependencies are present.

```ruby
validates :user, 'steel_wheel/query/dependency': true
```

### SteelWheel::Query::ExistsValidator

Validates that a record exists.

```ruby
validates :product, 'steel_wheel/query/exists': true
```

### SteelWheel::Query::VerifyValidator

Validates that an object is valid by merging its errors.

```ruby
validates :product, 'steel_wheel/query/verify': true
```

## Error Handling

### HTTP Status Codes

The library provides automatic HTTP status code management:

- `:ok` - Success
- `:bad_request` - Parameter validation errors
- `:unauthorized` - Authentication errors
- `:forbidden` - Authorization errors
- `:not_found` - Resource not found errors
- `:unprocessable_entity` - Business logic errors

### Generic Validation Keys

For older Rails versions (< 6.1), use `generic_validation_keys`:

```ruby
class MyHandler < SteelWheel::Handler
  generic_validation_keys(:not_found, :forbidden, :unprocessable_entity)
  
  def some_method
    errors.add(:not_found, "Resource not found")
  end
end
```

For Rails 6.1+, use the second argument:

```ruby
errors.add(:base, :not_found, "Resource not found")
```

## Usage Patterns

### Basic Handler

```ruby
class ProductsCreateHandler < SteelWheel::Handler
  params do
    attribute :name, string
    attribute :price, float
    
    validates :name, presence: true
    validates :price, numericality: { greater_than: 0 }
  end
  
  depends_on :current_user
  
  def on_validation_success
    product = Product.create!(
      name: params.name,
      price: params.price,
      user: current_user
    )
    # Handle success
  end
end
```

### Separate Components

```ruby
# app/handlers/products/create_handler.rb
class Products::CreateHandler < ApplicationHandler
  class Params < SteelWheel::Params
    attribute :name, string
    attribute :price, float
    validates :name, presence: true
  end
  
  class Query < SteelWheel::Query
    depends_on :current_user
    
    def can_create_product?
      current_user.admin? || current_user.products.count < 10
    end
  end
  
  class Command < SteelWheel::Command
    def call
      Product.create!(
        name: params.name,
        price: params.price,
        user: current_user
      )
    end
  end
  
  params Params
  query Query
  command Command
end
```

### Controller Integration

```ruby
class ProductsController < ApplicationController
  def create
    result = Products::CreateHandler.handle(input: params.to_unsafe_h) do |handler|
      handler.current_user = current_user
    end
    
    if result.success?
      redirect_to products_path, notice: 'Product created successfully'
    else
      render :new, status: result.status
    end
  end
end
```

## Rails Generators

### Application Handler Generator

```bash
rails generate steel_wheel:application_handler
```

Creates `app/handlers/application_handler.rb` as the base class.

### Handler Generator

```bash
rails generate steel_wheel:handler products/create
```

Creates `app/handlers/products/create_handler.rb`.

### Params Generator

```bash
rails generate steel_wheel:params products/create
```

Creates a params class within the handler.

### Scaffold Controller Generator

```bash
rails generate steel_wheel:scaffold_controller Product
```

Creates a complete CRUD controller using SteelWheel handlers.

## Dependencies

The library depends on:

- `railties` (>= 3.2, < 8)
- `easy_params` (~> 0.5)
- `memery` (~> 1)
- `nina` (~> 0.2)

## Best Practices

1. **Separation of Concerns**: Keep each stage focused on its specific responsibility
2. **Error Handling**: Use appropriate HTTP status codes for different error types
3. **Validation**: Validate early and provide clear error messages
4. **Dependencies**: Explicitly declare all dependencies using `depends_on`
5. **Memoization**: Use memoization for expensive operations
6. **Testing**: Test each component separately for better isolation

## Advanced Usage

### Custom Callbacks

```ruby
class MyHandler < SteelWheel::Handler
  def on_validation_success
    # Custom logic after successful validation
    call_command
    send_notifications
  end
  
  def on_validation_failure
    # Custom logic after validation failure
    log_errors
    send_error_notifications
  end
end
```

### Complex Validations

```ruby
class ComplexHandler < SteelWheel::Handler
  params do
    attribute :start_date, date
    attribute :end_date, date
    
    validate :date_range_valid
    
    private
    
    def date_range_valid
      return unless start_date && end_date
      
      if start_date > end_date
        errors.add(:end_date, "must be after start date")
      end
    end
  end
end
```

### Transaction Handling

```ruby
class SafeHandler < SteelWheel::Handler
  def on_validation_success
    ActiveRecord::Base.transaction do
      perform_operations
    rescue => e
      errors.add(:base, :unprocessable_entity, e.message)
      raise ActiveRecord::Rollback
    end
  end
  
  private
  
  def perform_operations
    # Your business logic here
  end
end
```

## Testing

### RSpec Examples

```ruby
RSpec.describe Products::CreateHandler do
  let(:params) { { name: "Test Product", price: 10.0 } }
  let(:handler) { described_class.new(params) }
  
  describe '#handle' do
    context 'with valid params' do
      it 'creates a product' do
        expect { handler.handle }.to change(Product, :count).by(1)
      end
      
      it 'returns success' do
        result = handler.handle
        expect(result).to be_success
      end
    end
    
    context 'with invalid params' do
      let(:params) { { name: "", price: -1 } }
      
      it 'does not create a product' do
        expect { handler.handle }.not_to change(Product, :count)
      end
      
      it 'returns failure' do
        result = handler.handle
        expect(result).not_to be_success
        expect(result.status).to eq(:bad_request)
      end
    end
  end
end
```

## Migration Guide

### From Version 0.5.x to 0.6.x

- Update your Gemfile to use the new version
- Review any custom error handling as the error system has been improved
- Test your handlers to ensure compatibility

## Troubleshooting

### Common Issues

1. **Missing Dependencies**: Ensure all required gems are installed
2. **Validation Errors**: Check that all required attributes are present
3. **HTTP Status Issues**: Verify that error keys match expected HTTP status codes
4. **Callback Issues**: Ensure callback methods are properly defined

### Debug Mode

Enable debug logging to trace handler execution:

```ruby
Rails.logger.level = Logger::DEBUG
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for your changes
4. Ensure all tests pass
5. Submit a pull request

## License

This gem is available as open source under the terms of the MIT License.