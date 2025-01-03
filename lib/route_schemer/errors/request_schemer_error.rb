# frozen_string_literal: true

module RouteSchemer
  # Custom error class for schema validation failures in RouteSchemer.
  # This error is raised when request or response parameters fail JSON schema validation.
  class RequestSchemerError < StandardError
    # @return [Array<Hash>] Details of the validation failures
    attr_reader :details

    # Initialize a new RequestSchemerError
    # @param message [String] The error message
    # @param details [Array<Hash>, nil] Detailed validation errors from JSONSchemer
    def initialize(message, details = nil)
      @details = details
      super(process_error(message))
    end

    def process_error(message)
      # TODO: format error message
      message
    end
  end
end
