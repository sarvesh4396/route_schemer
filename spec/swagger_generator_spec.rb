# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteSchemer::SwaggerGenerator do
  let(:foo_route_schemer) do
    stub_const("FooRouteSchemer", Class.new do
      def self.demo_request_schema
        { type: "object", properties: { name: { type: "string" } } }
      end

      def self.demo_response_schema
        { type: "object", properties: { success: { type: "boolean" } } }
      end
    end)
  end

  describe ".generate" do
    it "builds a document keyed by controller, then action, with the request/response schemas" do
      document = described_class.generate([foo_route_schemer])

      expect(document).to eq(
        "Foo" => {
          "demo" => {
            request: { type: "object", properties: { name: { type: "string" } } },
            response: { type: "object", properties: { success: { type: "boolean" } } }
          }
        }
      )
    end

    it "omits whichever side (request/response) isn't defined for an action" do
      response_only = stub_const("ResponseOnlyRouteSchemer", Class.new do
        def self.show_response_schema
          { type: "object" }
        end
      end)

      document = described_class.generate([response_only])

      expect(document["ResponseOnly"]["show"]).to eq(response: { type: "object" })
    end

    it "skips classes with no request/response schema methods at all" do
      empty_class = stub_const("EmptyRouteSchemer", Class.new)

      expect(described_class.generate([empty_class])).to eq({})
    end
  end

  describe ".generate_from_loaded_classes" do
    it "discovers loaded *RouteSchemer classes, excluding ApplicationRouteSchemer" do
      foo_route_schemer
      stub_const("ApplicationRouteSchemer", Class.new do
        def self.should_not_appear_request_schema
          { type: "object" }
        end
      end)

      document = described_class.generate_from_loaded_classes

      expect(document).to have_key("Foo")
      expect(document).not_to have_key("Application")
    end
  end
end
