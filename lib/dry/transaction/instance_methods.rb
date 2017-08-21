require "dry/monads/either"
require "dry/transaction/result_matcher"

module Dry
  module Transaction
    module InstanceMethods
      include Dry::Monads::Either::Mixin

      attr_reader :steps
      attr_reader :operations
      attr_reader :listeners

      def initialize(steps: (self.class.steps), listeners: nil, **operations)
        @steps = steps.map { |step|
          operation =
            if methods.include?(step.step_name) || private_methods.include?(step.step_name)
              method(step.step_name)
            else
              operations[step.step_name]
            end
          step.with(operation: operation)
        }
        @operations = operations
        subscribe(listeners) unless listeners.nil?
      end

      def call(input = nil, &block)
        assert_step_arity

        result = steps.inject(Right(input), :bind)

        if block
          ResultMatcher.(result, &block)
        else
          result.or { |step_failure|
            # Unwrap the value from the StepFailure and return it directly
            Left(step_failure.value)
          }
        end
      end

      def subscribe(listeners)
        @listeners = listeners

        if listeners.is_a?(Hash)
          listeners.each do |step_name, listener|
            steps.detect { |step| step.step_name == step_name }.subscribe(listener)
          end
        else
          steps.each do |step|
            step.subscribe(listeners)
          end
        end
      end

      def with_step_args(**step_args)
        assert_valid_step_args(step_args)

        new_steps = steps.map { |step|
          if step_args[step.step_name]
            step.with(call_args: step_args[step.step_name])
          else
            step
          end
        }

        self.class.new(steps: new_steps, listeners: listeners, **operations)
      end

      private

      def respond_to_missing?(name, _include_private = false)
        steps.any? { |step| step.step_name == name }
      end

      def method_missing(name, *args, &block)
        step = steps.detect { |s| s.step_name == name }
        super unless step

        operation = operations[step.step_name]
        raise NotImplementedError, "no operation +#{step.operation_name}+ defined for step +#{step.step_name}+" unless operation

        operation.(*args, &block)
      end

      def assert_valid_step_args(step_args)
        step_args.each_key do |step_name|
          unless steps.any? { |step| step.step_name == step_name }
            raise ArgumentError, "+#{step_name}+ is not a valid step name"
          end
        end
      end

      def assert_step_arity
        steps.each do |step|
          num_args_required = step.arity >= 0 ? step.arity : ~step.arity
          num_args_supplied = step.call_args.length + 1 # add 1 for main `input`

          if num_args_required > num_args_supplied
            raise ArgumentError, "not enough arguments supplied for step +#{step.step_name}+"
          end
        end
      end
    end
  end
end
