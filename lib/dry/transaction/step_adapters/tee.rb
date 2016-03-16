module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Tee
        def call(step, *args, input)
          step.operation.call(*args, input)
          Right(input)
        end
      end

      register :tee, Tee.new
    end
  end
end
