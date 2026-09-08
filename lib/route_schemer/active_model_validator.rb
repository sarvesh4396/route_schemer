# frozen_string_literal: true

require "active_model"

module RouteSchemer
  # Bridges RouteSchemer's JSON Schema validation into ActiveModel's validation ecosystem, so
  # any ActiveModel (plain form objects, ActiveRecord models, etc.) can validate its attributes
  # against a JSON schema and surface failures through the familiar `errors` API.
  #
  # @example Validate a plain form object against a schema
  #   class SignupForm
  #     include ActiveModel::Model
  #
  #     attr_accessor :email, :age
  #
  #     validates_with RouteSchemer::ActiveModelValidator, schema: {
  #       type: "object",
  #       required: ["email"],
  #       properties: {
  #         email: { type: "string", error_message: "Email is required" },
  #         age: { type: "integer" }
  #       }
  #     }
  #   end
  #
  #   form = SignupForm.new(age: "not a number")
  #   form.valid? # => false
  #   form.errors[:email] # => ["Email is required"]
  #   form.errors[:age]   # => ["value at `/age` is not an integer"]
  class ActiveModelValidator < ActiveModel::Validator
    def validate(record)
      schemer = JSONSchemer.schema(resolve_schema(record))
      data = record_attributes(record)

      return if schemer.valid?(data)

      schemer.validate(data).each do |error|
        add_error(record, error)
      end
    end

    private

    def resolve_schema(record)
      schema = options[:schema]
      schema.respond_to?(:call) ? schema.call(record) : schema
    end

    def record_attributes(record)
      if record.respond_to?(:attributes)
        record.attributes.symbolize_keys
      else
        record.instance_values.symbolize_keys
      end
    end

    def add_error(record, error)
      # A "required" violation has no data_pointer of its own (it fires at the object level,
      # listing every missing key in `details`), so each missing key needs to be expanded into
      # its own attribute-level error rather than falling through to :base.
      return add_missing_key_errors(record, error) if error["type"] == "required"

      attribute = error["data_pointer"].to_s.delete_prefix("/")
      schema = error["schema"]
      message = schema.is_a?(Hash) ? schema["error_message"] : nil
      record.errors.add(attribute.empty? ? :base : attribute.to_sym, message || error["error"])
    end

    def add_missing_key_errors(record, error)
      schema = error["schema"]
      missing_keys = error.dig("details", "missing_keys") || []
      missing_keys.each do |key|
        message = schema.is_a?(Hash) ? schema.dig("properties", key, "error_message") : nil
        record.errors.add(key.to_sym, message || "can't be blank")
      end
    end
  end
end
