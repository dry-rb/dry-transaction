module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Tee
        include Dry::Monads::Either::Mixin
        include Resolver

        def call(step, input, *args)
          resolve(step, input, *args)

          Right(input)
        end
      end

      register :tee, Tee.new
    end
  end
end
