# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

group :test do
  gem "pry-byebug", platform: :mri
  gem "dry-container"
end

group :tools do
  gem "pry"
end

group :development, :test do
  gem "bundler"
  gem "rake", ">= 12.3.3"
  gem "rspec"
  gem "yard"
end
