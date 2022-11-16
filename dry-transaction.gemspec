# frozen_string_literal: true

# this file is synced from dry-rb/template-gem project

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/transaction/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-transaction"
  spec.authors       = ["Tim Riley"]
  spec.email         = ["tim@icelab.com.au"]
  spec.license       = "MIT"
  spec.version       = Dry::Transaction::VERSION.dup

  spec.summary       = "Business Transaction Flow DSL"
  spec.description   = spec.summary
  spec.homepage      = "https://dry-rb.org/gems/dry-transaction"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-transaction.gemspec", "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["changelog_uri"]     = "https://github.com/dry-rb/dry-transaction/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]   = "https://github.com/dry-rb/dry-transaction"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/dry-rb/dry-transaction/issues"

  spec.required_ruby_version = ">= 2.7.0"

  # to update dependencies edit project.yml
  spec.add_runtime_dependency "dry-core", "~> 1.0"
  spec.add_runtime_dependency "dry-events", "~> 1.0"
  spec.add_runtime_dependency "dry-matcher", "~> 0.10"
  spec.add_runtime_dependency "dry-monads", "~> 1.6"

end
