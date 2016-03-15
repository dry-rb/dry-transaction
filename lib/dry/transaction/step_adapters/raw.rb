module Dry
  module Transaction
    module StepAdapters
      # @api private
      class Raw < Base
        def call(*args, input)
          operation.call(*args, input)
        end
      end

      register :step, Raw
    end
  end
end
