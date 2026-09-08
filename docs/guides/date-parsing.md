# Guide: Date & Date-Time Parsing

Request payloads carry dates as plain strings (`"2024-01-15"`, `"2024-01-15T10:30:00Z"`). Rather
than converting them by hand in every action, declare the JSON Schema `format` keyword and
RouteSchemer converts them into real `Date`/`Time` objects for you, automatically, once
validation has already confirmed the string matches that format.

```ruby
class BookingRouteSchemer < ApplicationRouteSchemer
  def self.create_request_schema
    {
      type: "object",
      properties: {
        check_in: { type: "string", format: "date" },        # -> Date
        confirmed_at: { type: "string", format: "date-time" } # -> Time
      }
    }
  end
end
```

```ruby
def create
  data = validated_params
  data[:check_in]      # => #<Date: 2024-01-15>
  data[:confirmed_at]  # => #<Time: 2024-01-15 10:30:00 UTC>
end
```

## How it works

1. JSONSchemer validates the request as usual, including checking `format: "date"` /
   `format: "date-time"` -- so an invalid date string (`"not-a-date"`) still raises
   `RequestSchemerError` exactly as any other schema violation would, *before* any parsing is
   attempted.
2. Only after validation succeeds does RouteSchemer walk the schema's declared properties and
   replace each `date`/`date-time` string with a `Date` (via `Date.parse`) or `Time` (via
   `Time.iso8601`) object.
3. This applies recursively to nested `type: "object"` properties too.

## Scope

This only applies to **request** validation (`validated_params` with the default `request:
true`) -- response schemas are left untouched, since a response payload is something your own
code already built (you control its types) rather than something to coerce.

It only converts properties whose schema declares `format: "date"` or `format: "date-time"` --
everything else passes through unchanged.

## Rendering it back out

`Date`/`Time` serialize to their ISO 8601 string form automatically via `render json:`, so this
round-trips cleanly without extra work on the response side.
