module Dry
  module Transaction
    # @api private
    class Stack
      RETURN = -> x { x }

      def initialize(steps)
        @stack = compile(steps)
      end

      def call(m)
        @stack.(m)
      end

      private

      def compile(steps)
        steps.reverse.reduce(RETURN) do |next_step, step|
          proc { |m| m.bind { |value| step.(value, next_step) } }
        end
      end
    end
  end
end
