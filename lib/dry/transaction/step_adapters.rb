require "dry-container"

module Dry
  class Transaction
    class StepAdapters
      extend Dry::Container::Mixin
    end
  end
end

require "dry/transaction/step_adapters/map"
require "dry/transaction/step_adapters/raw"
require "dry/transaction/step_adapters/tee"
require "dry/transaction/step_adapters/try"
