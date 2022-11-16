# frozen_string_literal: true

RSpec.configure do |config|
  config.include Dry::Monads[:result]
end
