# SteelWheel
[![Maintainability](https://api.codeclimate.com/v1/badges/a197758aa1cfde54f0e1/maintainability)](https://codeclimate.com/github/andriy-baran/steel_wheel/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a197758aa1cfde54f0e1/test_coverage)](https://codeclimate.com/github/andriy-baran/steel_wheel/test_coverage)
[![Gem Version](https://badge.fury.io/rb/steel_wheel.svg)](https://badge.fury.io/rb/steel_wheel)

SteelWheel is a comprehensive Rails gem for building highly structured service objects with built-in validation, filtering, callbacks, and form handling capabilities.

## Concepts

SteelWheel provides a robust framework for creating service objects (handlers) that encapsulate business logic with the following key features:

### Core Components

- **Handlers**: Service objects that encapsulate business logic with built-in validation and error handling
- **Parameters**: Type-safe parameter validation using EasyParams
- **Forms**: Integration with [ActionForm::Rails::Base](https://github.com/andriy-baran/action_form) for form handling and validation
- **Filters**: Query filtering capabilities for data operations
- **Callbacks**: Success and failure callback mechanisms
- **Preconditions**: Multi-level validation (URL params, form params, handler validation)
- **Shortcuts**: Convenient methods for common patterns (dependencies, verification, finders)

### Key Features

- **Structured Validation**: Multi-level validation with proper HTTP status codes
- **Filtering System**: Built-in query filtering with custom filter definitions
- **Callback System**: Success and failure callbacks with status-specific handling
- **Form Integration**: Seamless integration with [ActionForm::Rails::Base](https://github.com/andriy-baran/action_form) for form handling
- **Generator Support**: Rails generators for rapid development
- **HTTP Status Management**: Automatic HTTP status code handling for different error types

## Complete Handling Process

### Operation Execution Flow

The complete operation flow follows this sequence:

1. **Initialization**
   ```ruby
   handler = Products::CreateHandler.new(params)
   # - Prepares input parameters
   # - Separates URL params from form params
   # - Sets up form scope if defined
   ```

2. **Validation Phase**
   ```ruby
   handler.handle(:call) do |handler|
     # 1. Validates url_params
     # 2. Validates form_params (if present)
     # 3. Validates handler custom validations
     # 4. Calls dependencies, verifications, finders
   end
   ```

3. **Execution Phase** (only if validation passes)
   ```ruby
   # Calls the specified method (default: :call)
   handler.send(:call)
   ```

4. **Callback Phase**
   ```ruby
   if handler.success?
     handler.success_callback  # Calls success block
   else
     handler.failure_callback   # Calls failure block for current status
   end
   ```

### Validation Flow

The handler validation process follows a strict three-level validation hierarchy:

1. **URL Parameters Validation** (`url_params`)
   - Validates route parameters, query parameters, and controller params
   - Uses `SteelWheel::Params` (extends EasyParams)
   - Sets HTTP status to `:bad_request` on failure
   - Errors are merged into the main handler errors

2. **Form Parameters Validation** (`form_params`)
   - Validates form data when present
   - Uses EasyParams for type-safe validation
   - Sets HTTP status to `:unprocessable_entity` on failure
   - Creates form object with validation errors

3. **Handler Validation** (custom validation)
   - Validates business logic, dependencies, and custom rules
   - Uses ActiveModel validations with custom validators
   - Sets custom HTTP status codes based on error types
   - Includes dependency, verification, and existence validations

#### Status Code Management

SteelWheel automatically manages HTTP status codes based on validation results:

- **URL Parameters Invalid**: `:bad_request` (400)
- **Form Parameters Invalid**: `:unprocessable_entity` (422)
- **Dependencies Missing**: `:not_found` (404)
- **Verification Failed**: `:unprocessable_entity` (422)
- **Custom Validation Errors**: Based on error type
- **Success**: `:ok` (200)

#### Error Handling and Form Integration

When validation fails, SteelWheel automatically:

1. **Sets appropriate HTTP status**
2. **Creates form object with errors** (if form validation failed)
3. **Merges all validation errors** into handler.errors, except form errors
4. **Calls appropriate failure callback**
5. **Provides form object to views** for error display

This ensures seamless integration between validation, form handling, and view rendering without manual error management.


#### Form Integration in Controllers
```ruby
class ProductsController < ApplicationController
  action :create, act: :call do |handler|
    handler.success do
      redirect_to handler.product, notice: 'Product was successfully created.'
    end

    handler.failure do
      @form = handler.form # <-- form with errors
      render :new
    end
  end
end
```

### Advanced Filtering System

SteelWheel's filtering system provides automatic query filtering based on form parameters.

To implement filtering, you need to:
1. Define a search form that inherits from [`ActionForm::Base`](https://github.com/andriy-baran/action_form) (no authenticity token, does not support nested forms)
2. Create filters for each form input parameter
3. Set up an initial scope for the data

#### Filterable Methods
```ruby
class Products::IndexHandler < ApplicationHandler
  def form_attributes
    { method: :get, action: helpers.products_path, params: form_params }
  end

  form Products::SearchForm

  # Make a method filterable
  filterable def products
    helpers.current_user.includes(:category, :store)
  end

  # Define filters for form parameters
  filter :category_id do |scope, value|
    scope.where(category_id: value)
  end
end
```

#### Automatic Filter Application
```ruby
# In controller
action :index do |handler|
  @products = handler.products  # Automatically applies filters from form_params
  @form = handler.form         # Form object with search parameters
end
```

The filtering system automatically:
1. **Extracts search parameters** from form_params
2. **Applies corresponding filters** to the scope
3. **Handles missing filters** with clear error messages
4. **Maintains form state** for pagination and search persistence

### Parameter Processing and Scoping

SteelWheel automatically handles parameter scoping and separation:

#### Form Scope Configuration
```ruby
class Products::CreateHandler < ApplicationHandler
  # Form parameters will be extracted from params[:product]
  form Products::ModelForm

  def call
    # form_params contains only :product scoped parameters
    # url_params contains route and query parameters
  end
end
```

#### Parameter Separation
```ruby
# Input: { id: 1, product: { name: "Widget", price: 10.99 } }
handler = Products::CreateHandler.new(params)

handler.url_params.id        # => 1
handler.form_params.name    # => "Widget"
handler.form_params.price   # => 10.99
```

### Memoization and Performance

SteelWheel includes automatic memoization for expensive operations:

```ruby
class Products::ShowHandler < ApplicationHandler
  # Memoized - only called once per request
  finder :product, -> { Product.includes(:category, :store).find(url_params.id) }

  # Memoized - only called once per request
  finder :related_products, -> { product.related_products.limit(5) }

  # Memoized - only called once per request
  memoize def expensive_calculation
    # Complex calculation that should only run once
  end
end
```

## Installation

### Requirements

- Ruby >= 2.6
- Rails >= 3.2, < 8.1
- EasyParams ~> 0.6.3
- ActionForm (for form handling)
- Memery ~> 1

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'steel_wheel'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install steel_wheel
```

### Dependencies

SteelWheel depends on:
- **EasyParams**: For parameter validation and type safety
- **[ActionForm](https://github.com/andriy-baran/action_form)**: For form handling and validation (ActionForm::Rails::Base)
- **Memery**: For memoization of expensive operations
- **ActiveModel**: For validation and error handling
- **Railties**: For Rails integration and generators

## Usage

### Generators

SteelWheel provides several generators to quickly scaffold handlers and forms:

#### Application Handler
Generate a base application handler:

```bash
bin/rails g steel_wheel:application_handler
```

This creates `app/handlers/application_handler.rb` as a base class for all handlers.

#### Individual Handler
Generate a specific handler:

```bash
bin/rails g steel_wheel:handler products/create
```

This creates `app/handlers/products/create_handler.rb`.

#### Form Handler
Generate a form handler:

```bash
bin/rails g steel_wheel:form products/model
```

This creates `app/handlers/products/model_form.rb`.

#### Scaffold Controller
Generate a complete CRUD controller with handlers:

```bash
bin/rails g steel_wheel:scaffold_controller Product name:string price:decimal active:boolean
```

This creates:
- `app/controllers/products_controller.rb`
- `app/handlers/products/index_handler.rb`
- `app/handlers/products/create_handler.rb`
- `app/handlers/products/update_handler.rb`
- `app/handlers/products/model_form.rb`
- `app/handlers/products/search_form.rb`
- `lib/templates/erb/scaffold/_form.html.erb.tt` (form template)

### Basic Handler Example

```ruby
class Products::CreateHandler < ApplicationHandler
  url_params do
    param :store_id, :integer, required: true
  end

  form Products::ModelForm

  depends_on :store, :product
  finder :store, -> { Store.find(url_params.store_id) }, validate_existence: true

  def call
    @product = store.products.create!(form_params.to_h)
  end

  def form_attributes
    { model: product }
  end
end
```

### Advanced Features

#### Filtering
```ruby
class Products::IndexHandler < ApplicationHandler
  form Products::SearchForm

  filterable :products

  def products
    Product.includes(:category)
  end

  filter :category_id do |scope, value|
    scope.where(category_id: value)
  end

  filter :min_price do |scope, value|
    scope.where('price >= ?', value)
  end

  filter :max_price do |scope, value|
    scope.where('price <= ?', value)
  end
end
```

#### Callbacks
```ruby
Products::CreateHandler.handle(:call, params) do |handler|
  handler.success do |handler|
    # Send notification email
    ProductMailer.created(handler.product).deliver_now
  end

  handler.failure(:bad_request, :unprocessable_entity) do |handler|
    # Log validation errors
    Rails.logger.error "Product creation failed: #{handler.errors.full_messages}"
  end

  handler.failure(:not_found) do |handler|
    # render not found page
    render file: Rails.root.join('public', '404.html').to_s, status: handler.http_status
  end
end
```

#### Query Validators
SteelWheel includes three custom validators for common patterns:

- **DependencyValidator**: Validates that required dependencies are present
- **VerifyValidator**: Validates that method results are valid (calls `valid?` on the result)
- **ExistsValidator**: Validates that objects exist (not blank)

#### Shortcuts
```ruby
class Products::UpdateHandler < ApplicationHandler
  # Define dependencies that must be present
  # errors.add :base, :not_found, message: "Product is missing"
  depends_on :product
  depends_on :store, validate_provided: { message: 'record is required' }

  # Define verification methods
  # same as
  #   if category.invalid?
  #     category.errors.each do |error|
  #       errors.add(:category, :unprocessable_entity, message: error.message)
  #     end
  #   end
  verify def category
    Category.new(url_params.category_name)
  end
  def entity= Entity.new
  verify :entity, valid: {
    base: true,
    message: { base: true,
      id: -> (object, data) { "Please provide valid entity id" }, # message per attribute
    }
  }

  # Define finders with existence validation
  # errors.add(:product, :not_found, message: 'not found')
  finder :product, -> { owner.products.find(url_params.id) },
          validate_existence: {
            base: true, # add to base
            message: -> (object, data) { "Couldn't find Product with 'id'=#{object.url_params.id}" }
          }
  finder :store, -> { product.store }, validate_existence: true

  def owner
    helpers.current_user
  end
end
```

### HTTP Status Codes and Error Handling

SteelWheel provides comprehensive HTTP status code management for different types of errors:

#### Adding Errors with Status Codes

```ruby
# Add errors with specific HTTP status codes as errror details
errors.add(:base, :unprocessable_entity, 'Validation failed')
errors.add(:base, :not_found, 'Resource not found')
errors.add(:base, :forbidden, 'Access denied')
```

#### Generic Validation Keys (Rails < 6.1)

For Rails versions before 6.1, SteelWheel provides `generic_validation_keys` to prevent status codes from appearing in error messages:

```ruby
# Default setup
generic_validation_keys(:not_found, :forbidden, :unprocessable_entity, :bad_request, :unauthorized)

# Custom setup in your handler
class SomeHandler < ApplicationHandler
  generic_validation_keys(:not_found, :forbidden, :unprocessable_entity, :bad_request, :unauthorized, :payment_required)
end
```

#### Rails 6.1+ Error Handling

In Rails 6.1+, use the second argument for error types:

```ruby
errors.add(:base, :unprocessable_entity, 'Validation failed')
errors.add(:base, :not_found, 'Resource not found')
```

#### Automatic Status Code Handling

SteelWheel automatically sets HTTP status codes based on validation results:

- **URL Parameters**: `:bad_request` for invalid URL parameters
- **Form Parameters**: `:unprocessable_entity` for invalid form data
- **Handler Validation**: Custom status codes based on error types

### Controller Integration

#### Basic Controller Usage

```ruby
class ApplicationController < ActionController::Base
  #
  def failure_callbacks(handler)
    handler.failure(:not_found) do
      render file: Rails.root.join('public', '404.html').to_s, status: handler.http_status
    end
  end
end
```
#### Rails Integration with `action` Helper

SteelWheel provides Rails integration through a Railtie that adds a convenient `action` helper method to controllers. This helper automatically integrates handlers with controllers and sets up the `helpers` attribute for view context access:

```ruby
class ProductsController < ApplicationController
  before_action :authenticate_account!

  # GET /products
  action :index do |handler|
    @products = handler.products
    @form = handler.form
  end

  # GET /products/1
  action :show, handler: :update do |handler|
    @product = handler.product
  end

  # GET /products/new
  action :new, handler: :create do |handler|
    @product = handler.product
    @form = handler.form
  end

  # GET /products/1/edit
  action :edit, handler: :update do |handler|
    @product = handler.product
    @form = handler.form
  end

  # POST /products
  action :create, act: :call do |handler| # act tells handler to call provided method after completion of validation process
    handler.success do
      redirect_to handler.product, notice: 'Product was successfully created.'
    end

    handler.failure do
      @product = handler.product
      @form = handler.form
      render :new
    end
  end

  # PATCH/PUT /products/1
  action :update, act: :call do |handler|
    handler.success do
      redirect_to handler.product, notice: 'Product was successfully updated.'
    end

    handler.failure do
      @form = handler.form
      @product = handler.product
      render :edit
    end
  end

  # DELETE /products/1
  action :destroy, handler: :update, act: :destroy do |handler|
    redirect_to products_url, notice: 'Product was successfully destroyed.'
  end
end
```

#### Generated Controller Features

The scaffold controller generator creates controllers with:

- **Automatic Handler Integration**: Uses the `action` helper for seamless handler integration
- **Success/Failure Callbacks**: Built-in success and failure handling with appropriate redirects
- **Form Integration**: Automatic form object creation and error handling using [ActionForm](https://github.com/andriy-baran/action_form)
- **RESTful Actions**: Complete CRUD operations (index, show, new, create, edit, update, destroy)
- **Flash Messages**: Success and error notifications
- **Error Rendering**: Automatic error form rendering for create/update actions
- **Form Templates**: Creates ERB form templates for scaffold forms
- **Helper Integration**: Sets up view context through the `helpers` attribute

#### Action Helper Parameters

The `action` helper accepts several parameters:

- `action_name` - The controller action name
- `class_name` - Custom handler class name (optional)
- `handler` - Handler name (defaults to action_name)
- `act` - Method to call on handler (default `nil`)
- `&block` - Block executed with handler instance

## API Reference

### Handler Methods

#### Core Methods
- `call` - Main business logic method (must be implemented by subclasses)
- `handle(action_name, &block)` - Execute handler with optional action and block
- `success?` - Returns true if handler executed successfully
- `status` - Returns HTTP status code based on validation results

#### Parameter Methods
- `url_params` - Access validated URL parameters (SteelWheel::Params instance)
- `form_params` - Access validated form parameters (EasyParams instance)
- `form(attrs)` - Get form object with attributes ([ActionForm::Rails::Base](https://github.com/andriy-baran/action_form) instance)
- `form_attributes` - Must be implemented to return hash of attributes for form

#### Validation Methods
- `depends_on(*attrs, validate_provided: true)` - Define required dependencies
- `verify(*attrs, valid: true)` - Define method that will call `valid?` on method and copy errors onto handler object
- `finder(name, scope, validate_existence: false)` - Define finder methods with optional existence validation

#### Filtering Methods
- `filter(name, &block)` - Define a filter for query parameters
- `filterable(name)` - Make a method filterable with form parameters
- `apply_filters(scope, search_params)` - Apply filters to a scope

#### Callback Methods
- `success(&block)` - Define success callback
- `failure(*statuses, &block)` - Define failure callback for specific status

### Class Methods

#### Generators
- `rails g steel_wheel:application_handler` - Generate base application handler
- `rails g steel_wheel:handler Name` - Generate specific handler
- `rails g steel_wheel:form Name` - Generate form handler
- `rails g steel_wheel:scaffold_controller Name attributes` - Generate CRUD scaffold

#### Configuration
- `url_params(klass = nil, &block)` - Define URL parameter validation
- `form(klass = nil, &block)` - Define form validation
- `generic_validation_keys(*keys)` - Configure generic validation keys (Rails < 6.1)

### Rails Integration Methods

#### Railtie Integration
SteelWheel automatically integrates with Rails through a Railtie that:
- Adds the `action` helper method to all controllers
- Sets up the `helpers` attribute for view context access
- Provides automatic handler class resolution
- Includes default failure callbacks for 404 errors

#### Controller Helpers
- `action(action_name, class_name: nil, handler: action_name, act: nil, &block)` - Define controller action with handler integration
- `handler_class_for(class_name, action_name)` - Resolve handler class for controller action
- `failure_callbacks(handler)` - Set up default failure callbacks for handlers

#### Handler Attributes
- `helpers` - View context (set automatically by action helper)
- `http_status` - Current HTTP status code
- `input` - Raw input parameters from controllers
- `form_input` - Form-specific input parameters

### Error Classes

- `SteelWheel::Error` - Base error class
- `SteelWheel::ActionNotImplementedError` - Raised when `call` method is not implemented
- `SteelWheel::FilterNotImplementedError` - Raised when a filter is not defined
- `SteelWheel::FormAttributesNotImplementedError` - Raised when `form_attributes` is not implemented

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andriy-baran/steel_wheel. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SteelWheel project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andriy-baran/steel_wheel/blob/master/CODE_OF_CONDUCT.md).
