module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Around
        include Dry::Monads::Result::Mixin

        def call(step, input, *args, &block)
          result = step.call_operation(input, *args, &block)

          unless result.is_a?(Dry::Monads::Result)
            raise ArgumentError, "step +#{step.step_name}+ must return a Result object"
          end

          result
        end
      end

      register :around, Around.new
    end
  end
end
