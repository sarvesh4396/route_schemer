# Guide: Strict vs. Lenient Validation

By default, `validated_params` is **strict**: if the incoming data doesn't match the schema, it
raises `RouteSchemer::RequestSchemerError` immediately. That's the right behavior for most API
endpoints -- reject bad input before your controller action runs.

Sometimes you don't want a hard failure, though -- a partial-update endpoint that tolerates
missing optional fields, or a background import that wants to report *all* problems at once
instead of stopping at the first one. For that, pass `strict: false`:

```ruby
class ReportsController < ApplicationController
  def create
    data = validated_params(strict: false)

    if schema_errors.empty?
      Report.create!(data)
      render json: { success: true }
    else
      render json: { success: false, errors: schema_errors.map { |e| e["error"] } },
             status: :unprocessable_entity
    end
  end
end
```

With `strict: false`:

- No exception is raised, even if the data is invalid.
- `data` is still permitted/filtered down to the schema's declared properties.
- `schema_errors` (a controller-level reader RouteSchemer adds for you) holds the raw JSONSchemer
  error list -- empty when validation passed, populated when it didn't.

`schema_errors` is always available after calling `validated_params`, regardless of `strict`, so
you can inspect it even in the default strict mode from a `rescue_from` handler or a test.

## Combining with custom error messages

`schema_errors` entries are the same JSONSchemer error hashes used internally to build
`RequestSchemerError`'s message, so `error["schema"]["error_message"]` (see
[custom-error-messages.md](custom-error-messages.md)) is available on each one too.
