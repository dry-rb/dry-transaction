module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Check
        include Dry::Monads::Either::Mixin

        def call(step, input, *args)
          res = step.operation.call(*args, input)
          res == true || res.is_a?(Success) ? Success(input) : Failure(input)
        end
      end

      register :check, Check.new
    end
  end
end
