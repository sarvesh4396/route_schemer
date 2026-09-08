# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteSchemer do
  # RouteSchemer::Engine includes this module into ActionController::Base itself during Rails
  # boot (see spec_helper), so any ActionController::Base subclass already has it available.
  let(:controller_class) { Class.new(ActionController::Base) }
  let(:controller) { controller_class.new }

  let(:schema) do
    {
      type: "object",
      required: ["name"],
      properties: {
        name: { type: "string" },
        age: { type: "integer" }
      }
    }
  end

  def params_for(hash)
    ActionController::Parameters.new(hash)
  end

  describe "#validated_params" do
    it "raises ArgumentError when no schema is provided or derivable" do
      # `controller_path` is derived from the class name, so schema_for_current_action needs a
      # named controller (and a matching, but non-responding, RouteSchemer class) to resolve.
      stub_const("WidgetsController", Class.new(ActionController::Base))
      stub_const("WidgetsRouteSchemer", Class.new)
      widget_controller = WidgetsController.new
      widget_controller.instance_variable_set(:@_action_name, "create")

      expect do
        widget_controller.validated_params(schema: nil, params: params_for(name: "Ada"))
      end.to raise_error(ArgumentError, "No schema defined for validation")
    end

    it "returns validated, permitted, and coerced data for a valid request" do
      data = controller.validated_params(schema: schema, params: params_for(name: "Ada", age: "37", extra: "drop me"))
      expect(data).to eq("name" => "Ada", "age" => 37)
    end

    it "raises RequestSchemerError by default (strict: true) when data is invalid" do
      expect do
        controller.validated_params(schema: schema, params: params_for(age: "37"))
      end.to raise_error(RouteSchemer::RequestSchemerError)
    end

    it "does not permit-filter when permit: false" do
      data = controller.validated_params(schema: schema, params: params_for(name: "Ada", age: "37"), permit: false)
      expect(data).to eq("name" => "Ada", "age" => 37)
    end

    context "response validation (request: false)" do
      it "validates the given data without permitting/filtering it against ActionController::Parameters rules" do
        data = controller.validated_params(schema: schema, params: { name: "Ada", age: 37 }, request: false,
                                           permit: false)
        expect(data).to eq(name: "Ada", age: 37)
      end

      it "raises on an invalid response payload" do
        expect do
          controller.validated_params(schema: schema, params: { age: 37 }, request: false, permit: false)
        end.to raise_error(RouteSchemer::RequestSchemerError)
      end
    end
  end

  describe "strict mode" do
    it "does not raise when strict: false, and records the failure in #schema_errors" do
      data = nil
      expect do
        data = controller.validated_params(schema: schema, params: params_for(age: "37"), strict: false)
      end.not_to raise_error

      expect(data).to eq("age" => 37)
      expect(controller.schema_errors).not_to be_empty
      expect(controller.schema_errors.first["type"]).to eq("required")
    end

    it "leaves #schema_errors empty when validation succeeds" do
      controller.validated_params(schema: schema, params: params_for(name: "Ada", age: "37"), strict: false)
      expect(controller.schema_errors).to eq([])
    end
  end

  describe "custom error messages" do
    it "prefers a property-level error_message over JSONSchemer's default wording" do
      custom_schema = {
        type: "object",
        properties: {
          age: { type: "integer", error_message: "Age must be a whole number" }
        }
      }

      expect do
        controller.validated_params(schema: custom_schema, params: params_for(age: "not-a-number"))
      end.to raise_error(RouteSchemer::RequestSchemerError, "Age must be a whole number")
    end

    it "maps a missing required property back to that property's error_message" do
      custom_schema = {
        type: "object",
        required: ["name"],
        properties: {
          name: { type: "string", error_message: "Name is required" }
        }
      }

      expect do
        controller.validated_params(schema: custom_schema, params: params_for({}))
      end.to raise_error(RouteSchemer::RequestSchemerError, "Name is required")
    end

    it "falls back to JSONSchemer's default message when no error_message is defined" do
      expect do
        controller.validated_params(schema: schema, params: params_for(age: "not-a-number"))
      end.to raise_error(RouteSchemer::RequestSchemerError, /is not an integer/)
    end
  end

  describe "date parsing" do
    let(:date_schema) do
      {
        type: "object",
        properties: {
          dob: { type: "string", format: "date" },
          seen_at: { type: "string", format: "date-time" }
        }
      }
    end

    it "converts date/date-time strings into Date/Time objects after a successful request validation" do
      data = controller.validated_params(
        schema: date_schema,
        params: params_for(dob: "2024-01-15", seen_at: "2024-01-15T10:30:00Z")
      )

      expect(data["dob"]).to eq(Date.new(2024, 1, 15))
      expect(data["seen_at"]).to eq(Time.iso8601("2024-01-15T10:30:00Z"))
    end

    it "still raises (and does not attempt to parse) when the value does not match the declared format" do
      expect do
        controller.validated_params(schema: date_schema, params: params_for(dob: "not-a-date"))
      end.to raise_error(RouteSchemer::RequestSchemerError)
    end

    it "does not parse dates for response validation" do
      data = controller.validated_params(schema: date_schema, params: { dob: "2024-01-15" }, request: false,
                                         permit: false)
      expect(data[:dob]).to eq("2024-01-15")
    end
  end
end
