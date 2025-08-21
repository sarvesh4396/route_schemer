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
      # Format error message with detailed validation failures
      return message unless @details.is_a?(Array) && !@details.empty?

      formatted_errors = @details.map do |error|
        pointer = error["data_pointer"]
        schema_pointer = error["schema_pointer"]
        error_message = error["error"]

        if pointer && !pointer.empty?
          "Field '#{pointer}': #{error_message}"
        elsif schema_pointer && !schema_pointer.empty?
          "Schema '#{schema_pointer}': #{error_message}"
        else
          error_message
        end
      end

      base_message = message || "Schema validation failed"
      "#{base_message}. Details: #{formatted_errors.join("; ")}"
    end
  end
end