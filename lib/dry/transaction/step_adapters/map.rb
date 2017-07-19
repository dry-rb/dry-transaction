module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Map
        include Dry::Monads::Either::Mixin
        include Resolver

        def call(step, input, *args)
          Right(resolve(step, input, *args))
        end
      end

      register :map, Map.new
    end
  end
end
