require "dry-container"

module Dry
  module Transaction
    class StepAdapters
      extend Dry::Container::Mixin

      module Resolver
        def resolve(step, input, *args)
          if step.arity >= 1
            step.operation.call(input, *args)
          else
            step.operation.call
          end
        end
      end
    end
  end
end

require "dry/transaction/step_adapters/map"
require "dry/transaction/step_adapters/raw"
require "dry/transaction/step_adapters/tee"
require "dry/transaction/step_adapters/try"
