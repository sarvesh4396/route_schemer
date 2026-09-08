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

  included do
    # @return [Array<Hash>] the raw JSONSchemer errors from the most recent validation, if any.
    #   Populated even when `strict: false` suppresses the raised exception.
    attr_reader :schema_errors
  end

  def validated_params(schema: nil, params: nil, request: true, permit: true, strict: true)
    # Default to dynamically determined schema and params if not provided
    schema ||= schema_for_current_action(request)
    raise ArgumentError, "No schema defined for validation" unless schema

    params ||= self.params

    data = if request
             validate_request(schema, params, strict: strict)
           else
             validate_response(schema, params, strict: strict)
           end
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
  # @param strict [Boolean] when true (the default), raise RequestSchemerError on failure.
  #   When false, validation failures are recorded in `schema_errors` instead of raising.
  # @return [Hash] the validated and permitted parameters
  def validate_request(schema, data, strict: true)
    schemer = fetch_schema_object(schema)
    data = permitted_params(schema, data)
    check_for_error(schemer, data, strict: strict)
    # Runs even when strict: false left some other property invalid -- coerce_date_value only
    # ever touches values that already match their own declared format, so this can't surface a
    # field that failed validation as if it were a parsed date.
    data = parse_dates(schema, data)
    @permitted_params = data

    data # Return validated and permitted params
  end

  # @return [Boolean] whether the data was valid against the schema
  def check_for_error(schemer, data, strict: true)
    if schemer.valid?(data)
      @schema_errors = []
      return true
    end

    errors = schemer.validate(data).to_a
    @schema_errors = errors
    return false unless strict

    raise RequestSchemerError.new(custom_error_message(errors.first) || errors.first["error"], errors)
  end

  # Looks up a schema-defined `error_message` for a JSONSchemer error, so schema authors can
  # override JSONSchemer's default wording per-property (or for the whole schema).
  # @param error [Hash] a single error hash as returned by JSONSchemer::Schema#validate
  # @return [String, nil] the custom message, or nil to fall back to the default JSONSchemer message
  def custom_error_message(error)
    schema = error["schema"]
    return nil unless schema.is_a?(Hash)

    if error["type"] == "required"
      missing_keys = error.dig("details", "missing_keys") || []
      messages = missing_keys.filter_map { |key| schema.dig("properties", key, "error_message") }
      return messages.join(", ") if messages.any?
    end

    schema["error_message"]
  end

  def validate_response(schema, data, strict: true)
    schemer = fetch_schema_object(schema)
    check_for_error(schemer, data, strict: strict)
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

  # Converts validated request values into richer Ruby objects based on their schema's `format`
  # keyword. Runs only after validation has already succeeded, so any string reaching here is
  # already known to match its declared format.
  # @param schema [Hash] the JSON schema the data was validated against
  # @param data [Hash] the validated, permitted request data
  # @return [Hash] the same data, with date/date-time strings replaced by Date/Time objects
  def parse_dates(schema, data)
    return data unless data.is_a?(Hash)

    properties = schema[:properties] || {}
    data.each_key do |key|
      property_schema = properties[key.to_sym] || properties[key.to_s]
      next unless property_schema

      data[key] = parse_date_property(property_schema, data[key])
    end
    data
  end

  def parse_date_property(property_schema, value)
    return parse_dates(property_schema, value) if nested_object?(property_schema, value)

    coerce_date_value(value, property_schema[:format])
  end

  def nested_object?(property_schema, value)
    property_schema[:type] == "object" && value.is_a?(Hash)
  end

  def coerce_date_value(value, format)
    return value unless value.is_a?(String)

    case format
    when "date"
      Date.parse(value)
    when "date-time"
      Time.iso8601(value)
    else
      value
    end
  rescue ArgumentError
    # The value didn't actually match its declared format (schema validation should have
    # already caught this) -- leave it untouched rather than raising here.
    value
  end
end
