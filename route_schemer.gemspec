# frozen_string_literal: true

require_relative "lib/route_schemer/version"

Gem::Specification.new do |spec|
  spec.name = "route_schemer"
  spec.version = RouteSchemer::VERSION
  spec.authors = ["Sarvesh Kumar Dwivedi"]
  spec.email = ["heysarvesh@pm.me"]

  spec.summary = "Validate request and response schemas for Rails routes using RouteSchemer"
  spec.description = "Validate your controller routes request and response schemas."
  spec.homepage = "https://www.github.com/sarvesh4396/route_schemer"

  s.extra_rdoc_files = ['README.md', 'LICENSE']
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  File.basename(__FILE__)
  spec.files = Dir["lib/**/*"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "json_schemer", "2.3.0"
  spec.add_dependency "rails", ">= 6.0", "< 8.0"
  spec.add_runtime_dependency "stringio", ">= 3.1.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
