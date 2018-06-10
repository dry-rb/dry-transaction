require "dry/monads/result"
require 'dry/events/publisher'
require "dry/transaction/step_failure"
require "dry/transaction/step_adapter"

module Dry
  module Transaction
    # @api private
    class Step
      UNDEFINED = Object.new.freeze
      RETURN = -> x { x }

      include Dry::Events::Publisher[name || object_id]
      include Dry::Monads::Result::Mixin

      register_event(:step)
      register_event(:step_succeeded)
      register_event(:step_failed)

      attr_reader :adapter
      attr_reader :name
      attr_reader :operation_name
      attr_reader :call_args

      def initialize(adapter:, name:, operation_name:, operation: nil, options:, call_args: [])
        @adapter = StepAdapter[adapter, operation, **options, step_name: name, operation_name: operation_name]
        @name = name
        @operation_name = operation_name
        @call_args = call_args
      end

      def with(operation: UNDEFINED, call_args: UNDEFINED)
        return self if operation == UNDEFINED && call_args == UNDEFINED

        new_operation = operation == UNDEFINED ? adapter.operation : operation
        new_call_args = call_args == UNDEFINED ? self.call_args : Array(call_args)

        self.class.new(
          adapter: adapter,
          name: name,
          operation_name: operation_name,
          operation: new_operation,
          options: adapter.options,
          call_args: new_call_args,
        )
      end

      def call(input, continue = RETURN)
        args = [input, *call_args]

        if adapter.yields?
          with_broadcast(args) { adapter.(args, &continue) }
        else
          continue.(with_broadcast(args) { adapter.(args) })
        end
      end

      def with_broadcast(args)
        publish(:step, step_name: name, args: args)

        yield.fmap { |value|
          publish(:step_succeeded, step_name: name, args: args, value: value)
          value
        }.or { |value|
          Failure(
            StepFailure.(self, value) {
              publish(:step_failed, step_name: name, args: args, value: value)
            }
          )
        }
      end

      def internal?
        !external?
      end

      def external?
        !!operation_name
      end

      def arity
        adapter.operation.arity
      end

      def operation
        adapter.operation
      end
    end
  end
end
