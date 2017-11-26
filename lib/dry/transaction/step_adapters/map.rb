module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Map
        include Dry::Monads::Result::Mixin

        def call(operation, _options, args)
          Success(operation.(*args))
        end
      end

      register :map, Map.new
    end
  end
end
