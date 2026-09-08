# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteSchemer::ActiveModelValidator do
  let(:form_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :email, :age

      validates_with RouteSchemer::ActiveModelValidator, schema: {
        type: "object",
        required: ["email"],
        properties: {
          email: { type: "string", error_message: "Email is required" },
          age: { type: "integer" }
        }
      }
    end
  end

  it "is valid when the attributes satisfy the schema" do
    form = form_class.new(email: "ada@example.com", age: 37)
    expect(form).to be_valid
  end

  it "adds the schema's custom error_message for the failing attribute" do
    form = form_class.new(age: 37)
    form.valid?
    expect(form.errors[:email]).to include("Email is required")
  end

  it "falls back to JSONSchemer's default message when no error_message is defined" do
    form = form_class.new(email: "ada@example.com", age: "not-a-number")
    form.valid?
    expect(form.errors[:age].first).to match(/is not an integer/)
  end

  it "supports a schema given as a callable, evaluated per record" do
    dynamic_class = Class.new do
      include ActiveModel::Model
      attr_accessor :role

      validates_with RouteSchemer::ActiveModelValidator, schema: lambda { |_record|
        { type: "object", required: ["role"], properties: { role: { type: "string" } } }
      }
    end

    record = dynamic_class.new
    record.valid?
    expect(record.errors[:role]).not_to be_empty
  end

  it "works against ActiveRecord-style objects too, reading #attributes instead of instance_values" do
    ar_like_class = Class.new do
      include ActiveModel::Model

      def attributes
        { "name" => nil }
      end

      validates_with RouteSchemer::ActiveModelValidator, schema: {
        type: "object",
        required: ["name"],
        properties: { name: { type: "string", error_message: "Name can't be blank" } }
      }
    end

    record = ar_like_class.new
    record.valid?
    expect(record.errors[:name]).to include("Name can't be blank")
  end
end
