# frozen_string_literal: true

require 'dry/monads/result'
require 'dry/transaction/result_matcher'
require 'dry/transaction/stack'

module Dry
  module Transaction
    module InstanceMethods
      include Dry::Monads::Result::Mixin

      attr_reader :steps
      attr_reader :operations
      attr_reader :listeners
      attr_reader :stack

      def initialize(*args, steps: (self.class.steps), listeners: nil, **operations)
        @steps = steps.map { |step|
          operation = resolve_operation(step, **operations)
          step.with(operation: operation)
        }
        @operations = operations
        @stack = Stack.new(@steps)
        subscribe(listeners) unless listeners.nil?

        next_super_method = method(__method__).super_method
        super_initialize = nil

        loop do
          if next_super_method.owner.name =~ /Dry::Transaction/
            next_super_method = next_super_method.super_method
          else
            super_initialize = next_super_method
            break
          end
        end

        if super_initialize && super_initialize.parameters.empty?
          super()
        elsif super_initialize
          super_kwarg_names = super_initialize.parameters.each_with_object([]) { |(type, name), names|
            names << name if [:key, :keyreq].include?(type)
          }

          super_kwargs = operations.each_with_object({}) { |(key, val), kwargs|
            kwargs[key] = val if super_kwarg_names.include?(key)
          }

          super(*args, **super_kwargs)
        end
      end

      def call(input = nil, &block)
        assert_step_arity

        result = stack.(Success(input))

        if block
          ResultMatcher.(result, &block)
        else
          result.or { |step_failure|
            # Unwrap the value from the StepFailure and return it directly
            Failure(step_failure.value)
          }
        end
      end

      def subscribe(listeners)
        @listeners = listeners

        if listeners.is_a?(Hash)
          listeners.each do |step_name, listener|
            steps.detect { |step| step.name == step_name }.subscribe(listener)
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
          if step_args[step.name]
            step.with(call_args: step_args[step.name])
          else
            step
          end
        }

        self.class.new(steps: new_steps, listeners: listeners, **operations)
      end

      private

      def respond_to_missing?(name, _include_private = false)
        steps.any? { |step| step.name == name }
      end

      def method_missing(name, *args, &block)
        step = steps.detect { |s| s.name == name }
        super unless step

        operation = operations[step.name]
        raise NotImplementedError, "no operation +#{step.operation_name}+ defined for step +#{step.name}+" unless operation

        operation.(*args, &block)
      end

      def resolve_operation(step, **operations)
        if step.internal? && operations[step.name]
          operations[step.name]
        elsif methods.include?(step.name) || private_methods.include?(step.name)
          method(step.name)
        elsif operations[step.name].respond_to?(:call)
          operations[step.name]
        elsif operations[step.name]
          raise InvalidStepError.new(step.name)
        else
          raise MissingStepError.new(step.name)
        end
      end

      def assert_valid_step_args(step_args)
        step_args.each_key do |step_name|
          unless steps.any? { |step| step.name == step_name }
            raise ArgumentError, "+#{step_name}+ is not a valid step name"
          end
        end
      end

      def assert_step_arity
        steps.each do |step|
          num_args_required = step.arity >= 0 ? step.arity : ~step.arity
          num_args_supplied = step.call_args.length + 1 # add 1 for main `input`

          if num_args_required > num_args_supplied
            raise ArgumentError, "not enough arguments supplied for step +#{step.name}+"
          end
        end
      end
    end
  end
end
