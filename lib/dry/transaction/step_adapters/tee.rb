module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Tee
        include Dry::Monads::Either::Mixin

        def call(step, input, *args)
          step.call_operation(input, *args)
          Right(input)
        end
      end

      register :tee, Tee.new
    end
  end
end
