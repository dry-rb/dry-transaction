# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

group :test do
  gem "pry-byebug", platform: :mri
end

group :tools do
  gem "pry"
end

group :development, :test do
  gem "bundler"
  gem "rspec"
  gem "yard"
end
