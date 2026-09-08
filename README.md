# RouteSchemer
 
[![Gem Version](https://badge.fury.io/rb/route_schemer.svg)](https://badge.fury.io/rb/route_schemer) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

**RouteSchemer** is a Ruby gem designed for Rails applications to streamline schema validation of requests and responses for API endpoints. It leverages `JSONSchemer` for validation against OpenAPI-style JSON schemas. This gem makes it easy to ensure that API payloads conform to predefined structures and simplifies error handling for mismatched data.

---

## 🌟 Why RouteSchemer?

As a developer with a background in Python's FastAPI, I noticed a gap in the Rails ecosystem for robust schema validation. FastAPI provides clear, built-in tools for validating and documenting API contracts, and I wanted to bring a similar experience to Rails. RouteSchemer fills this gap by making JSON schema validation seamless and Rails-friendly.

---

## 🚀 Features

- Automatically validate requests and responses against JSON schemas.
- Supports nested controllers and complex schema structures.
- Generates schema files for controllers using a Rails-like generator -- even before the
  controller itself exists.
- Provides a simple API to access validated and filtered parameters.
- Custom, schema-defined error messages for validation failures.
- Optional non-raising ("lenient") validation mode via `strict: false`.
- Converts validated `date`/`date-time` request strings into real `Date`/`Time` objects.
- Validate any `ActiveModel` (form objects, `ActiveRecord` models) against a schema via
  `RouteSchemer::ActiveModelValidator`.
- Generate an OpenAPI-style document straight from your existing schemas
  (`rake route_schemer:swagger`).

---

## 📦 Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add route_schemer
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install route_schemer
```

---

## 🛠️ Getting Started

### Step 1: Generate a Controller and a RouteSchemer

Create a new controller and corresponding RouteSchemer with:

```bash
rails g controller Foo demo
rails g route_schemer Foo demo
```

This will generate:

- A `FooController` with an action `demo`
- A schema file in `app/route_schemers/foo_route_schemer.rb`

### Step 2: Define a Schema

Edit the generated `FooRouteSchemer` file to define a schema:

```ruby
class FooRouteSchemer < ApplicationRouteSchemer
    def self.demo_request_schema
        {
            type: "object",
            properties: {
                name: { type: "string" },
                age: { type: "integer" }
            },
            required: ["name", "age"]
        }
    end

    def self.demo_response_schema
        {
            type: "object",
            properties: {
                success: { type: "boolean" },
                message: { type: "string" }
            },
            required: ["success"]
        }
    end
end
```

### Step 3: Use in the Controller

In `FooController`, use the validation helpers provided by the gem:
Make Sure to include `RouteSchemer` in `ApplicationController`

```ruby
class FooController < ApplicationController

    def demo
        @filtered_params = validated_params # auto fetches requests schema 

        # Your controller logic
        response = validated_params(request: false, permit: false) # auto fetches response schema
        render json: response, status: :ok
    end
end
```

The `validated_params` method automatically applies the request schema for the current action (`demo_request_schema` in this case).

The `validated_params(request: false, permit: false)` validates response and do not permits as we do not need to permit in case of response.

---

## 🔧 Advanced Usage

### Custom Schemas in Methods

You can override the default behavior of using `validated_params` with a custom schema:

```ruby
class FooController < ApplicationController
    def custom_action
        schema = CustomRouteSchemer.some_other_schema
        @filtered_params = validated_params(schema: schema)
        render json: { success: true }
    end
end
```

### Error Handling

RouteSchemer raises `RouteSchemer::RequestSchemerError` when validation fails. You can handle this error in your Rails application by rescuing it globally:

```ruby
class ApplicationController < ActionController::API
    rescue_from RouteSchemer::RequestSchemerError do |e|
        Rails.logger.debug e.details # has all errors
        render json: { error: e.message }, status: :unprocessable_entity
    end
end
```

Give any property a custom `error_message` to override JSONSchemer's default wording -- see the
[custom error messages guide](docs/guides/custom-error-messages.md).

### Lenient Validation (`strict: false`)

By default, invalid data raises. Pass `strict: false` to get the permitted data back without
raising, and inspect `schema_errors` yourself -- see the [strict-mode guide](docs/guides/strict-mode.md).

```ruby
data = validated_params(strict: false)
render json: { errors: schema_errors } if schema_errors.any?
```

### Date & Date-Time Parsing

Properties declared with `format: "date"` or `format: "date-time"` come back as real
`Date`/`Time` objects after a successful request validation -- see the
[date-parsing guide](docs/guides/date-parsing.md).

### ActiveModel Integration

Validate any `ActiveModel` (form objects, `ActiveRecord` models) against a schema with
`RouteSchemer::ActiveModelValidator` -- see the [ActiveModel guide](docs/guides/active-model.md).

```ruby
class SignupForm
    include ActiveModel::Model
    attr_accessor :email

    validates_with RouteSchemer::ActiveModelValidator, schema: SignupRouteSchemer.create_request_schema
end
```

### Swagger / OpenAPI Generation

Turn your existing `RouteSchemer` classes into an OpenAPI-style document with
`rake route_schemer:swagger` -- see the [Swagger generation guide](docs/guides/swagger-generation.md).

---

## 🧪 Testing

RouteSchemer ships with its own RSpec suite covering the concern, the generator, the ActiveModel
validator, and the swagger generator:

```bash
bundle exec rake       # runs the spec suite, then rubocop
bundle exec rspec      # just the spec suite
```

To test a controller action that uses RouteSchemer in your own app, make a request with a valid
or invalid payload and ensure that:

- A valid payload is processed successfully.
- An invalid payload triggers the appropriate error response.

---

## 📚 Guides

Deeper guides for individual features live in [docs/guides](docs/guides):

- [Strict vs. lenient validation](docs/guides/strict-mode.md)
- [Custom error messages](docs/guides/custom-error-messages.md)
- [Date & date-time parsing](docs/guides/date-parsing.md)
- [ActiveModel integration](docs/guides/active-model.md)
- [Swagger / OpenAPI generation](docs/guides/swagger-generation.md)
- [Generating schemas ahead of the controller](docs/guides/generator.md)

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch for your feature/bugfix.
3. Submit a pull request with a detailed description of your changes.

If you would like to streamline and standardize commit messages, please give a try to [pygitmate](https://github.com/sarvesh4396/pygitmate) also created by me.
---

## ⭐ Star the Repository

If you find this project helpful, consider starring the repository on GitHub to show your support!

[![Star this repo](https://img.shields.io/github/stars/sarvesh4396/route_schemer.svg?style=social)](https://github.com/sarvesh4396/route_schemer)

---

## 📜 License

RouteSchemer is open-source software licensed under the [MIT License](./LICENSE).

---

## Code of Conduct

Everyone interacting in the RouteSchemer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sarvesh4396/route_schemer/blob/master/CODE_OF_CONDUCT.md).

---

## 🙏 Acknowledgments

- Thanks to the creators of `JSONSchemer` for powering the schema validation.
- Inspired by Rails' generators and extensible architecture.
