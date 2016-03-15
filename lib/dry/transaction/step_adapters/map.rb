module Dry
  module Transaction
    module StepAdapters
      # @api private
      class Map < Base
        def call(*args, input)
          Right(operation.call(*args, input))
        end
      end

      register :map, Map
    end
  end
end
