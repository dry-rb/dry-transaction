module Dry
  module Transaction
    class Stack
      LOOPBACK = proc { |input| input }

      def initialize(steps)
        @stack = compile(steps)
      end

      def call(input)
        @stack.(input)
      end

      def compile(steps)
        steps.reverse.reduce(LOOPBACK) do |next_step, step|
          proc do |input|
            input.bind do |value|
              yielded = false

              result = step.(value) do |next_input|
                yielded = true

                next_step.(next_input)
              end

              if yielded
                result
              else
                next_step.(result)
              end
            end
          end
        end
      end
    end
  end
end
