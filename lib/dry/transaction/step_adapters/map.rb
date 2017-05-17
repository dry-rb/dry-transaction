module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Map
        include Dry::Monads::Either::Mixin

        def call(step, input, *args)
          Right(step.operation.call(input, *args))
        end
      end

      register :map, Map.new
    end
  end
end
