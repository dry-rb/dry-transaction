require "dry/monads/result"
require "wisper"
require "dry/transaction/step_failure"
require "dry/transaction/step_adapter"

module Dry
  module Transaction
    # @api private
    class Step
      UNDEFINED = Object.new.freeze
      RETURN = -> x { x }

      include Wisper::Publisher
      include Dry::Monads::Result::Mixin

      attr_reader :step_adapter
      attr_reader :step_name
      attr_reader :operation_name
      attr_reader :call_args

      def initialize(step_adapter, step_name, operation_name, operation, options, call_args = [])
        @step_adapter = StepAdapter[step_adapter, operation, **options, step_name: step_name]
        @step_name = step_name
        @operation_name = operation_name
        @call_args = call_args
      end

      def with(operation: UNDEFINED, call_args: UNDEFINED)
        return self if operation == UNDEFINED && call_args == UNDEFINED
        new_operation = operation == UNDEFINED ? step_adapter.operation : operation
        new_call_args = call_args == UNDEFINED ? self.call_args : Array(call_args)

        self.class.new(
          step_adapter,
          step_name,
          operation_name,
          new_operation,
          step_adapter.options,
          new_call_args
        )
      end

      def call(input, continue = RETURN)
        args = [input, *call_args]

        if step_adapter.yields?
          with_broadcast(args) { step_adapter.(args, &continue) }
        else
          continue.(with_broadcast(args) { step_adapter.(args) })
        end
      end

      def with_broadcast(args)
        broadcast :step_called, step_name, *args

        yield.fmap { |value|
          broadcast :step_succeeded, step_name, *args
          value
        }.or { |value|
          broadcast :step_failed, step_name, *args, value
          Failure(StepFailure.new(self, value))
        }
      end

      def arity
        step_adapter.operation.arity
      end

      def operation
        step_adapter.operation
      end
    end
  end
end
