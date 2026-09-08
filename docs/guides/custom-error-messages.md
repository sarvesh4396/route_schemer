# Guide: Custom Error Messages

By default, validation errors use JSONSchemer's own wording (e.g. `` value at `/age` is not an
integer ``). That's fine for logs, but rarely what you want to show a user. Add an
`error_message` alongside `type` on any property to override it:

```ruby
class SignupRouteSchemer < ApplicationRouteSchemer
  def self.create_request_schema
    {
      type: "object",
      required: ["email"],
      properties: {
        email: {
          type: "string",
          format: "email",
          error_message: "Please enter a valid email address"
        },
        age: {
          type: "integer",
          error_message: "Age must be a whole number"
        }
      }
    }
  end
end
```

```ruby
validated_params # raises RouteSchemer::RequestSchemerError, "Age must be a whole number"
                 # if age: "old" was submitted
```

`error_message` is a plain JSON Schema extension keyword -- JSONSchemer (like any JSON Schema
validator) ignores keywords it doesn't recognize, so it's safe to include alongside `type`,
`format`, etc. without affecting validation itself.

## Missing required fields

A missing *required* property doesn't have its own JSONSchemer error the way a type mismatch
does -- JSONSchemer reports a single object-level error listing every missing key. RouteSchemer
maps that back to each property's own `error_message` for you:

```ruby
{
  type: "object",
  required: ["name"],
  properties: {
    name: { type: "string", error_message: "Name is required" }
  }
}
```

Submitting no `name` raises `RequestSchemerError, "Name is required"` rather than JSONSchemer's
generic `"object at root is missing required properties: name"`. If more than one required
property is missing at once, their messages are joined with `, `.

## When no custom message is set

If a property has no `error_message`, RouteSchemer falls back to JSONSchemer's default wording,
so this is entirely opt-in -- you only need to add `error_message` to the properties you want to
override.

## In `RequestSchemerError`

Whatever message is picked (custom or default) is normalized -- surrounding whitespace stripped,
internal whitespace collapsed -- before becoming `error.message`. The full list of raw JSONSchemer
errors (with each one's own `schema`, `data_pointer`, etc.) is always available via
`error.details`, regardless of which message ended up on top:

```ruby
rescue_from RouteSchemer::RequestSchemerError do |e|
  render json: { error: e.message, details: e.details }, status: :unprocessable_entity
end
```

## ActiveModel integration

The same `error_message` keyword is honored by [`RouteSchemer::ActiveModelValidator`](active-model.md), so a single schema's custom messages work whether you're validating a controller request or an ActiveModel form object.
