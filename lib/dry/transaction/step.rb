require "dry/monads/result"
require "wisper"
require "dry/transaction/step_failure"

module Dry
  module Transaction
    # @api private
    class Step
      UNDEFINED = Object.new.freeze
      NOOP = :itself.to_proc.freeze

      include Wisper::Publisher
      include Dry::Monads::Result::Mixin

      attr_reader :step_adapter
      attr_reader :step_name
      attr_reader :operation_name
      attr_reader :operation
      attr_reader :options
      attr_reader :call_args

      def initialize(step_adapter, step_name, operation_name, operation, options, call_args = [])
        @step_adapter = step_adapter
        @step_name = step_name
        @operation_name = operation_name
        @operation = operation
        @options = options
        @call_args = call_args
      end

      def with(operation: UNDEFINED, call_args: UNDEFINED)
        return self if operation == UNDEFINED && call_args == UNDEFINED
        new_operation = operation == UNDEFINED ? self.operation : operation
        new_call_args = call_args == UNDEFINED ? self.call_args : call_args

        self.class.new(
          step_adapter,
          step_name,
          operation_name,
          new_operation,
          options,
          new_call_args
        )
      end

      def call(input, next_step = NOOP)
        args = [input] + Array(call_args)
        continue = once(next_step)

        with_broadcast(args, continue) do
          step_adapter.call(self, *args, &continue)
        end
      end

      def once(next_step)
        continued = false

        -> (input) do
          if continued
            input
          else
            continued = true
            next_step.(input)
          end
        end
      end

      def with_broadcast(args, continue)
        broadcast :step_called, step_name, *args

        result = yield.fmap { |value|
          broadcast :step_succeeded, step_name, *args
          value
        }.or { |value|
          broadcast :step_failed, step_name, *args, value
          Failure(StepFailure.new(self, value))
        }

        continue.(result)
      end

      def call_operation(*input, &continue)
        if arity.zero?
          operation.call(&continue)
        else
          operation.call(*input, &continue)
        end
      end

      def arity
        @arity ||=
          case operation
          when Proc, Method
            operation.arity
          else
            operation.method(:call).arity
          end
      end
    end
  end
end
