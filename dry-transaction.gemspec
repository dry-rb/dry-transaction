lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/transaction/version"

Gem::Specification.new do |spec|
  spec.name     = "dry-transaction"
  spec.version  = Dry::Transaction::VERSION
  spec.authors  = ["Tim Riley"]
  spec.email    = ["tim@icelab.com.au"]
  spec.license  = "MIT"

  spec.summary  = "Business Transaction Flow DSL"
  spec.homepage = "https://github.com/dry-rb/dry-transaction"

  spec.files = Dir["README.md", "LICENSE.md", "Gemfile*", "Rakefile", "lib/**/*", "spec/**/*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0.0"

  spec.add_runtime_dependency "dry-container", ">= 0.2.8"
  spec.add_runtime_dependency "kleisli"
  spec.add_runtime_dependency "wisper", ">= 1.6.0"

  spec.add_development_dependency "bundler", "~> 1.11.2"
  spec.add_development_dependency "rake", "~> 10.4.2"
  spec.add_development_dependency "rspec", "~> 3.3.0"
  spec.add_development_dependency "simplecov", "~> 0.10.0"
  spec.add_development_dependency "yard"
end
