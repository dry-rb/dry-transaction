# frozen_string_literal: true

require "bundler/setup"

require_relative "support/coverage"

begin
  require "pry"
  require "pry-byebug"
rescue LoadError;
end
require "dry-transaction"

SPEC_ROOT = Pathname(__dir__)

Dir.glob(SPEC_ROOT.join("support", "**", "*.rb")).each do |file|
  require_relative file
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "spec/examples.txt"

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed

  config.include Dry::Monads[:result], adapter: true
end
