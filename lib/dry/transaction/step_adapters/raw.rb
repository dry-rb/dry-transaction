module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Raw
        def call(step, *args, input)
          step.operation.call(*args, input)
        end
      end

      register :step, Raw.new
    end
  end
end
