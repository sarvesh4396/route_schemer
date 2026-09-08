# Guide: ActiveModel Integration

`validated_params` covers controller requests/responses. `RouteSchemer::ActiveModelValidator`
brings the same JSON Schema validation to any `ActiveModel` -- plain form objects, service
objects, or `ActiveRecord` models -- so you can reuse one schema wherever it's useful, and get
failures back through the ordinary `errors` API instead of an exception.

```ruby
class SignupForm
  include ActiveModel::Model

  attr_accessor :email, :age

  validates_with RouteSchemer::ActiveModelValidator, schema: {
    type: "object",
    required: ["email"],
    properties: {
      email: { type: "string", error_message: "Email is required" },
      age: { type: "integer" }
    }
  }
end

form = SignupForm.new(age: "not a number")
form.valid?          # => false
form.errors[:email]  # => ["Email is required"]
form.errors[:age]    # => ["value at `/age` is not an integer"]
```

## What gets validated

The validator reads `record.attributes` if the record defines it (as `ActiveRecord` models do),
falling back to `record.instance_values` for plain `ActiveModel::Model` objects (i.e. every
`attr_accessor`-backed instance variable). Either way, the resulting hash is what gets validated
against the schema.

## Custom error messages

`error_message` (see [custom-error-messages.md](custom-error-messages.md)) works exactly the same
way here as it does for `validated_params` -- set it per-property to override JSONSchemer's
default wording, and a missing required property's message comes from that property's own
`error_message`.

## Dynamic schemas

`schema:` also accepts a callable, given the record being validated -- handy when the schema
depends on the record's own state:

```ruby
validates_with RouteSchemer::ActiveModelValidator, schema: ->(record) {
  record.admin? ? AdminRouteSchemer.update_request_schema : UserRouteSchemer.update_request_schema
}
```

## Using it on an ActiveRecord model

```ruby
class Booking < ApplicationRecord
  validates_with RouteSchemer::ActiveModelValidator, schema: BookingRouteSchemer.create_request_schema
end
```

This runs alongside (not instead of) any other ActiveRecord/ActiveModel validations already
declared on the class.
