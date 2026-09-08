# Guide: Generating Schemas Ahead of the Controller

`rails g route_schemer` no longer requires the target controller to exist first. This is useful
when designing an API contract before writing the controller that will serve it -- write the
schema, then build the controller against it.

```bash
rails g route_schemer Foo demo
```

## If the controller doesn't exist yet

```
warning  Controller Foo does not exist at app/controllers/foo_controller.rb. Generating the
         schema anyway -- method names will not be checked.
   create  app/route_schemers/application_route_schemer.rb
   create  app/route_schemers/foo_route_schemer.rb
```

The schema file is generated normally; you just don't get the extra "does this method actually
exist" safety check until the controller shows up.

## If the controller already exists

The generator still checks that each action you named is actually defined on the controller, and
raises if one isn't -- so a typo in the action name is still caught immediately:

```bash
rails g route_schemer Foo demo
# ArgumentError: Method demo is not defined in Foo
```

This is unchanged from before -- only the "controller must already exist" requirement was
relaxed, not the method-name check.
