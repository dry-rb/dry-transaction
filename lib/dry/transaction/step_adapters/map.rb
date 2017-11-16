module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Map
        include Dry::Monads::Result::Mixin

        def call(step, input, *args)
          Right(step.call_operation(input, *args))
        end
      end

      register :map, Map.new
    end
  end
end
