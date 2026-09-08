# RouteSchemer Guides

Detailed guides for specific features, beyond the quick examples in the main
[README](../../README.md):

- [Strict vs. lenient validation](strict-mode.md) -- validate without raising, and inspect
  `schema_errors` yourself.
- [Custom error messages](custom-error-messages.md) -- override JSONSchemer's default wording
  per-property.
- [Date & date-time parsing](date-parsing.md) -- get real `Date`/`Time` objects out of validated
  request params.
- [ActiveModel integration](active-model.md) -- validate any ActiveModel (form objects,
  ActiveRecord models) against a schema.
- [Swagger / OpenAPI generation](swagger-generation.md) -- turn your existing `RouteSchemer`
  classes into an OpenAPI-style document.
- [Generating schemas ahead of the controller](generator.md) -- what changed now that the
  generator no longer requires the controller to exist first.
