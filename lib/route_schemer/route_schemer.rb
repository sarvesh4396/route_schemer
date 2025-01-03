# frozen_string_literal: true

# A module for JSON schema validation in Rails controllers.
# Provides methods for validating request and response parameters against JSON schemas.
# This module is automatically included in Rails controllers through the RouteSchemer::Engine.
#
# @example Validating request parameters in a controller
#   def create
#     params = validated_params(schema: MyRouteSchemer.create_request_schema)
#     # ...
#   end
module RouteSchemer
  extend ActiveSupport::Concern

  def validated_params(schema: nil, params: nil, request: true, permit: true)
    # Default to dynamically determined schema and params if not provided
    schema ||= schema_for_current_action(request)
    raise ArgumentError, "No schema defined for validation" unless schema

    params ||= self.params

    data = request ? validate_request(schema, params) : validate_response(schema, params)
    permit ? @permitted_params || permitted_params(schema, data) : data
  end

  def schema_for_current_action(request)
    # Derive the associated RouteSchemer class (e.g., FooController -> FooRouteSchemer)
    route_schemer_class = "#{controller_path.camelize}RouteSchemer".constantize
    schema_method_name = request ? "#{action_name}_request_schema" : "#{action_name}_response_schema"
    # Look up the schema method on the RouteSchemer class
    return route_schemer_class.public_send(schema_method_name) if route_schemer_class.respond_to?(schema_method_name)

    nil
  end

  # Get a JSONSchemer object for the provided schema
  # @param schema [Hash] the JSON schema to validate against
  # @return [JSONSchemer::Schema] the JSONSchemer object
  def fetch_schema_object(schema)
    JSONSchemer.schema(
      schema,
      before_property_validation: proc do |data, property, property_schema, _|
        value = data[property]
        case property_schema["type"]
        when "integer"
          data[property] = value.to_i if value.is_a?(String) && value.match?(/^\d+$/)
        when "number"
          data[property] = value.to_f if value.is_a?(String) && value.match?(/^[-+]?[0-9]*\.?[0-9]+$/)
        end
      end
    )
  end

  private

  # Validate the request parameters against the provided schema
  # @param schema [Hash] the JSON schema to validate against
  # @param data [Hash, ActionController::Parameters] the incoming request parameters
  # @return [Hash] the validated and permitted parameters
  def validate_request(schema, data)
    schemer = fetch_schema_object(schema)
    data = permitted_params(schema, data)
    check_for_error(schemer, data)
    @permitted_params = data

    data # Return validated and permitted params
  end

  def check_for_error(schemer, data)
    return if schemer.valid?(data)

    errors = schemer.validate(data)
    error_message = errors.first["error"]
    raise RequestSchemerError.new(error_message, errors)
  end

  def validate_response(schema, data)
    schemer = fetch_schema_object(schema)
    check_for_error(schemer, data)
    data
  end

  # Filters and permits parameters based on a given schema.
  # @param schema [Hash] The schema defining the permitted fields.
  # @param params [ActionController::Parameters, Hash] The parameters to be filtered.
  # @return [Hash] The filtered parameters.
  def permitted_params(schema, params)
    data = {}
    if params.is_a?(ActionController::Parameters)
      data = params.permit(*get_permitted_fields(schema)).to_h
    elsif params.is_a?(Hash)
      data = params.select { |key, _| schema[:properties].key?(key.to_sym) }
    end
    data
  end

  # Get the permitted fields from the schema
  # @param schema [Hash] the JSON schema to extract permitted fields from
  # @return [Array] the list of permitted fields for rails
  def get_permitted_fields(schema)
    properties = schema[:properties] || {}
    properties.map do |key, value|
      case value[:type]
      when "object"
        { key.to_sym => get_permitted_fields(value) }
      when "array"
        value[:items][:type] == "object" ? { key.to_sym => get_permitted_fields(value[:items]) } : { key.to_sym => [] }
      else
        key.to_sym
      end
    end
  end
end
