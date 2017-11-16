module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Tee
        include Dry::Monads::Result::Mixin

        def call(step, input, *args)
          step.call_operation(input, *args)
          Success(input)
        end
      end

      register :tee, Tee.new
    end
  end
end
