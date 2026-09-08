# frozen_string_literal: true

namespace :route_schemer do
  desc "Generate an OpenAPI-style JSON document from every app/route_schemers/**/*.rb schema"
  task swagger: :environment do
    require "json"
    require "route_schemer/swagger_generator"

    Dir.glob(Rails.root.join("app", "route_schemers", "**", "*.rb")).sort.each { |file| require file }

    document = RouteSchemer::SwaggerGenerator.generate_from_loaded_classes
    output_path = Rails.root.join("swagger", "route_schemer.json")
    FileUtils.mkdir_p(output_path.dirname)
    File.write(output_path, JSON.pretty_generate(document))

    puts "RouteSchemer swagger document written to #{output_path}"
  end
end
