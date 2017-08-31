require "dry/monads/either"
require "wisper"
require "dry/transaction/step_failure"

module Dry
  module Transaction
    # @api private
    class Step
      UNDEFINED = Object.new.freeze

      include Wisper::Publisher
      include Dry::Monads::Either::Mixin

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
          new_call_args,
        )
      end

      def call(input)
        args = [input] + Array(call_args)
        result = step_adapter.call(self, *args)

        result.fmap { |value|
          broadcast :"#{step_name}_success", value
          value
        }.or { |value|
          broadcast :"#{step_name}_failure", *args, value
          Left(StepFailure.new(self, value))
        }
      end

      def call_operation(*input)
        if arity.zero?
          operation.call
        else
          operation.call(*input)
        end
      end

      def arity
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
