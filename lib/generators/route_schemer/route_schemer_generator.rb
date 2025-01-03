# frozen_string_literal: true

require "rails/generators"

# A Rails generator that creates route schema files for controllers.
# This generator validates the existence of controllers and their methods,
# then generates both application-wide and controller-specific route schema files.
#
# @example Generate schema for UserController with index and show actions
#   rails generate route_schemer User index show
#
# @param controller_name [String] The name of the controller to generate schema for (e.g., 'Users' or 'Api::Users')
# @param methods [Array<String>] List of controller methods/actions to include in the schema
#
# @raise [ArgumentError] If the controller doesn't exist or specified methods are not defined
class RouteSchemerGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  argument :controller_name, type: :string
  argument :methods, type: :array, default: []

  def validate_controller
    # Ensure controller_name is properly formatted (e.g., Foo or Foo::Bar)
    controller_path = File.join("app", "controllers", "#{controller_name.underscore}_controller.rb")
    unless File.exist?(controller_path)
      raise ArgumentError, "Controller #{controller_name} does not exist at #{controller_path}"
    end

    # Attempt to constantize the controller name
    begin
      @controller_class = "#{controller_name}Controller".constantize
    rescue NameError
      raise ArgumentError, "Controller class #{controller_name} could not be found. Ensure it is defined correctly."
    end

    # Validate each method in the controller class
    methods.each do |method|
      unless @controller_class.instance_methods.include?(method.to_sym)
        raise ArgumentError, "Method #{method} is not defined in #{controller_name}"
      end
    end
  end

  def create_route_schemer_file
    # Define the path based on the nested structure of `controller_name`
    schemer_directory = File.join("app", "route_schemers")

    # Create nested directories if they don't exist
    FileUtils.mkdir_p(schemer_directory) unless Dir.exist?(schemer_directory)

    # Generate the application route schemer file
    application_schemer_file = File.join("app", "route_schemers", "application_route_schemer.rb")
    unless File.exist?(application_schemer_file)
      template "application_route_schemer_template.rb.tt",
               application_schemer_file
    end

    # Generate the schemer file always override
    schemer_file = File.join(schemer_directory, "#{controller_name.demodulize.underscore}_route_schemer.rb")
    template "route_schemer_template.rb.tt", schemer_file
  end
end
