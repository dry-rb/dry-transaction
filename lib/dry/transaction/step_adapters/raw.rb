require "dry/monads/result"

module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Raw
        include Dry::Monads::Result::Mixin

        def call(step, input, *args)
          result = step.call_operation(input, *args)

          unless result.is_a?(Dry::Monads::Result)
            raise ArgumentError, "step +#{step.step_name}+ must return a Result object"
          end

          result
        end
      end

      register :step, Raw.new
    end
  end
end
