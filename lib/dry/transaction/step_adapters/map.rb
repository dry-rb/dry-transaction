module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Map
        def call(step, *args, input)
          Right(step.operation.call(*args, input))
        end
      end

      register :map, Map.new
    end
  end
end
