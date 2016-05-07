module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Map
        include Dry::Monads::Either::Mixin

        def call(step, *args, input)
          Right(step.operation.call(*args, input))
        end
      end

      register :map, Map.new
    end
  end
end
