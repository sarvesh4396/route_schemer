# frozen_string_literal: true

module RouteSchemer
  # Module to handle type coercion for different data types
  module TypeCoercion
    extend self

    # Coerce a value based on the schema type and format
    # @param value [Object] the value to coerce
    # @param schema [Hash] the schema definition for the property
    # @return [Object] the coerced value
    def coerce_value(value, schema)
      return value unless value.is_a?(String)
      return value unless schema.is_a?(Hash)

      type = schema["type"] || schema[:type]
      format = schema["format"] || schema[:format]

      case type
      when "integer"
        coerce_integer(value)
      when "number"
        coerce_number(value)
      when "boolean"
        coerce_boolean(value)
      when "string"
        coerce_string(value, format)
      else
        value
      end
    rescue StandardError
      # Return original value if coercion fails
      value
    end

    private

    def coerce_integer(value)
      return value unless value.match?(/^-?\d+$/)

      value.to_i
    end

    def coerce_number(value)
      return value unless value.match?(/^-?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?$/)

      value.include?(".") || value.match?(/[eE]/) ? value.to_f : value.to_i
    end

    def coerce_boolean(value)
      case value.downcase
      when "true", "1", "yes", "on"
        true
      when "false", "0", "no", "off"
        false
      else
        value
      end
    end

    def coerce_string(value, format)
      case format
      when "date"
        parse_date(value)
      when "date-time"
        parse_datetime(value)
      when "time"
        parse_time(value)
      else
        value
      end
    end

    def parse_date(value)
      # Try different date formats
      [
        "%Y-%m-%d",
        "%m/%d/%Y",
        "%d/%m/%Y",
        "%Y/%m/%d"
      ].each do |format|
        return Date.strptime(value, format)
      rescue ArgumentError
        next
      end

      # If specific formats fail, try general parsing
      Date.parse(value)
    rescue ArgumentError
      value
    end

    def parse_datetime(value)
      # Try ISO 8601 format first
      return DateTime.iso8601(value) if value.match?(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)

      # Try general parsing
      DateTime.parse(value)
    rescue ArgumentError
      value
    end

    def parse_time(value)
      # Try different time formats
      [
        "%H:%M:%S",
        "%H:%M",
        "%I:%M:%S %p",
        "%I:%M %p"
      ].each do |format|
        return Time.strptime(value, format)
      rescue ArgumentError
        next
      end

      # If specific formats fail, try general parsing
      Time.parse(value)
    rescue ArgumentError
      value
    end
  end
end
