# Guide: Swagger / OpenAPI Generation

Every `*RouteSchemer` class you write is already a request/response schema per controller action
-- `RouteSchemer::SwaggerGenerator` collects them into a single OpenAPI-style JSON document, so
you don't maintain a separate spec by hand alongside your validation schemas.

## Rake task

```bash
rake route_schemer:swagger
```

This requires every file under `app/route_schemers/**/*.rb`, discovers every loaded
`*RouteSchemer` class (except the shared `ApplicationRouteSchemer` base), and writes the combined
document to `swagger/route_schemer.json`:

```json
{
  "Foo": {
    "demo": {
      "request": { "type": "object", "properties": { "name": { "type": "string" } } },
      "response": { "type": "object", "properties": { "success": { "type": "boolean" } } }
    }
  }
}
```

The top-level key is the controller name (`FooRouteSchemer` -> `"Foo"`), each action name maps to
its `request`/`response` schema -- whichever side(s) that `RouteSchemer` class actually defines.

## Programmatic use

```ruby
# Build a document from an explicit list of classes:
RouteSchemer::SwaggerGenerator.generate([FooRouteSchemer, BarRouteSchemer])

# Or discover everything currently loaded:
RouteSchemer::SwaggerGenerator.generate_from_loaded_classes
```

Use this if you want to post-process the document -- wrap it into a full OpenAPI 3.0 envelope
(`openapi:`, `info:`, `paths:`, ...) tailored to your app's routes, feed it into `rswag`, or serve
it from an endpoint rather than a static file.

## Keeping it up to date

Since the document is generated straight from the same schemas `validated_params` enforces at
request time, it can't drift out of sync with your actual validation -- rerun the rake task (or
wire it into your deploy/CI pipeline) whenever a `RouteSchemer` class changes.
