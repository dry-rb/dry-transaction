module Dry
  module Transaction
    # @api private
    class Stack
      LOOPBACK = :itself.to_proc.freeze

      def initialize(steps)
        @stack = compile(steps)
      end

      def call(m)
        @stack.(m)
      end

      def compile(steps)
        steps.reverse.reduce(LOOPBACK) do |next_step, step|
          proc { |m| m.bind { |value| step.(value, next_step) } }
        end
      end
    end
  end
end
