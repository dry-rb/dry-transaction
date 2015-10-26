require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new

require "rubocop/rake_task"
RuboCop::RakeTask.new

task default: :ci

desc "Run the test suite"
task ci: %w(rubocop spec)
