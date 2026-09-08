# frozen_string_literal: true

require "spec_helper"

RSpec.describe RouteSchemer::RequestSchemerError do
  it "exposes the raw JSONSchemer details it was raised with" do
    details = [{ "error" => "value at `/age` is not an integer" }]
    error = described_class.new("value at `/age` is not an integer", details)

    expect(error.details).to eq(details)
  end

  it "normalizes surrounding/duplicate whitespace out of the message" do
    error = described_class.new("  value at `/age`   is not an integer  \n")

    expect(error.message).to eq("value at `/age` is not an integer")
  end

  it "defaults details to nil when none are given" do
    error = described_class.new("boom")

    expect(error.details).to be_nil
  end
end
