## [Released]

## [0.3.0] - 2026-09-08

- Support Rails up to 8.1.3.1; widen `json_schemer` to `>= 2.3.0, < 3.0`.
- Add `strict:` option to `validated_params` for non-raising validation, backed by a new
  `schema_errors` reader.
- Support schema-defined `error_message` per property (and for missing required properties),
  overriding JSONSchemer's default wording.
- Parse `format: "date"` / `format: "date-time"` request properties into `Date`/`Time` objects
  after successful validation.
- The `route_schemer` generator no longer requires the target controller to exist; it warns and
  still generates the schema file.
- Add `RouteSchemer::ActiveModelValidator`, bridging schema validation into `ActiveModel`'s
  `errors` API.
- Add `RouteSchemer::SwaggerGenerator` and `rake route_schemer:swagger` to generate an
  OpenAPI-style document from existing `RouteSchemer` classes.
- Add an RSpec test suite covering the concern, generator, ActiveModel validator, and swagger
  generator.
- Add `docs/guides` with detailed guides for each of the above.

## [0.1.0] - 2024-01-04

- Initial release

## [0.2.0] - 2024-01-04

- Version Bump
