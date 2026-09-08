# frozen_string_literal: true

require "rails"
require "action_controller"
require "action_controller/railtie"
require "route_schemer"

# RouteSchemer only makes sense wired into a real Rails app (it needs ActionController::Base,
# ActionController::Parameters, and the Rails::Engine initializer chain to have actually run),
# so the spec suite boots a minimal, throwaway Rails::Application once for the whole run rather
# than mocking these pieces away.
class RouteSchemerTestApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(IO::NULL)
  config.secret_key_base = "route_schemer_test"
end
Rails.application.initialize! unless Rails.application.initialized?

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
