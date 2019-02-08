module Dry
  module Transaction
    # @api private
    class Stack
      def initialize(steps)
        @stack = compile(steps)
      end

      def call(m)
        @stack.(m)
      end

      private

      def compile(steps)
        proc do |m|
          steps.reduce([[StepAdapter::INITIAL_INPUT_KEY, m]]) do |acc, step|
            step_inputs = step.inputs(acc)
            prev_step_output = acc.last[1]
            acc + [[step.name, prev_step_output.bind { step.(step_inputs.map(&:value!)) }]]
          end.last[1]
        end
      end
    end
  end
end
