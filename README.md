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
- Generates schema files for controllers using a Rails-like generator.
- Provides a simple API to access validated and filtered parameters.
- Custom error handling for schema mismatches.

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

---

## 🧪 Testing

To test a controller action with RouteSchemer, make a request with a valid or invalid payload and ensure that:

- A valid payload is processed successfully.
- An invalid payload triggers the appropriate error response.

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

## TODO
- [ ] Parsing of date strings to objects after validating in request.
- [ ] Add more comprehensive documentation with examples.
- [ ] Provide detailed guides for common use cases and best practices.
- [ ] Make controller existence optional, allowing generation even if the controller doesn't exist.
- [ ] Explore support for `ActiveModel` to enhance schema validation using the Rails ecosystem.
- [ ] Add support for custom error messages in schema validations.
- [ ] Set up continuous integration and deployment pipelines.
- [ ] Enhance test coverage and add more unit and integration tests.
- [ ] Add auto integration to support swagger generation of present schemers.
- [ ] Implement strict option as optional for schema validation so that schema validation passes but no errors.
