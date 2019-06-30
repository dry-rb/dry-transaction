source "https://rubygems.org"

gemspec

group :test do
  gem "simplecov"
  gem "codeclimate-test-reporter"
  gem "pry-byebug", platform: :mri
  gem "dry-container"
end

group :tools do
  gem "pry"
  gem "rubocop"
end

group :development, :test do
  gem "bundler"
  gem "rake", "~> 11.2", ">= 11.2.2"
  gem "rspec"
  gem "simplecov"
  gem "yard"
end
