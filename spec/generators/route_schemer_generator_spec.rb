# frozen_string_literal: true

require "spec_helper"
require "rails/generators"
require "generators/route_schemer/route_schemer_generator"
require "tmpdir"
require "fileutils"

RSpec.describe RouteSchemerGenerator do
  def run_generator(args, root)
    generator = described_class.new(args)
    generator.destination_root = root
    generator.invoke_all
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @tmp_root = dir
      example.run
    end
  end

  it "generates the schema files even when the controller does not exist" do
    expect { run_generator(%w[Foo demo], @tmp_root) }.not_to raise_error

    schemer_file = File.join(@tmp_root, "app/route_schemers/foo_route_schemer.rb")
    expect(File).to exist(schemer_file)
    expect(File.read(schemer_file)).to include("def self.demo_request_schema")
  end

  it "also generates the shared ApplicationRouteSchemer base class" do
    run_generator(%w[Foo demo], @tmp_root)

    expect(File).to exist(File.join(@tmp_root, "app/route_schemers/application_route_schemer.rb"))
  end

  it "still raises when the controller exists but is missing the requested method" do
    # `validate_controller` checks File.exist? against the process's current directory (a
    # pre-existing quirk of the generator, unrelated to this fix), so the on-disk file has to be
    # created relative to a chdir; the constant itself is stubbed rather than `require`d so it
    # doesn't leak into other examples.
    controllers_dir = File.join(@tmp_root, "app/controllers")
    FileUtils.mkdir_p(controllers_dir)
    File.write(File.join(controllers_dir, "foo_controller.rb"), "class FooController\n  def index; end\nend\n")
    stub_const("FooController", Class.new { def index; end })

    Dir.chdir(@tmp_root) do
      expect { run_generator(%w[Foo demo], @tmp_root) }
        .to raise_error(ArgumentError, "Method demo is not defined in Foo")
    end
  end

  it "succeeds when the controller exists and defines the requested method" do
    controllers_dir = File.join(@tmp_root, "app/controllers")
    FileUtils.mkdir_p(controllers_dir)
    File.write(File.join(controllers_dir, "bar_controller.rb"), "class BarController\n  def demo; end\nend\n")
    stub_const("BarController", Class.new { def demo; end })

    Dir.chdir(@tmp_root) do
      expect { run_generator(%w[Bar demo], @tmp_root) }.not_to raise_error
    end
  end
end
