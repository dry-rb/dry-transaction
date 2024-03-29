# frozen_string_literal: true

module Dry
  module Transaction
    class StepAdapters
      extend Dry::Core::Container::Mixin
    end
  end
end

require "dry/transaction/step_adapters/check"
require "dry/transaction/step_adapters/map"
require "dry/transaction/step_adapters/raw"
require "dry/transaction/step_adapters/tee"
require "dry/transaction/step_adapters/try"
require "dry/transaction/step_adapters/around"
