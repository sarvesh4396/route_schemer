# frozen_string_literal: true

require "json_schemer"
require "active_support/concern"
require "route_schemer/route_schemer"
require "route_schemer/errors/request_schemer_error"

# A module for JSON schema validation in Rails controllers.
# Provides methods for validating request/response parameters against JSON schemas.
# This module is automatically included in Rails controllers through the Engine.
module RouteSchemer
  # Rails engine that automatically includes RouteSchemer functionality in Rails controllers.
  # Hooks into the Rails initialization process to include the RouteSchemer module
  # in all ActionController::Base descendants.
  class Engine < ::Rails::Engine
    initializer "route_schemer.include_module" do
      ActiveSupport.on_load(:action_controller_base) do
        include RouteSchemer
      end
    end
  end
end
