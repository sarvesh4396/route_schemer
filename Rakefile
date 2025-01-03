# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"

RuboCop::RakeTask.new do |task|
  task.options = ["--autocorrect"]
end

task default: :rubocop
