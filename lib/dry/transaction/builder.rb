require "dry/transaction/result_matcher"
require "dry/transaction/step"
require "dry/transaction/operation_resolver"

module Dry
  class Transaction
    class Builder < Module
      attr_reader :container
      attr_reader :step_adapters

      attr_reader :class_dsl_mod
      attr_reader :resolver_mod

      DSL = Class.new(Module)

      def initialize(container: nil, step_adapters:)
        @container = container
        @step_adapters = step_adapters

        @class_dsl_mod = DSL.new
        define_dsl

        @resolver_mod = OperationResolver.new(container)
      end

      def included(klass)
        klass.extend(class_dsl_mod)
        klass.send(:include, resolver_mod)
        klass.send(:include, InstanceMethods)
      end

      def define_dsl
        class_dsl_mod.class_exec(step_adapters) do |step_adapters|
          # TODO: I wonder if we could move this out of the class_exec and into a straight-up module
          def steps
            @steps ||= []
          end

          step_adapters.keys.each do |adapter_name|
            define_method(adapter_name) do |step_name, with: nil, **options, &block|
              operation_name = with
              operation = nil # operations are resolved only when transactions are instantiated

              steps << Step.new(
                step_adapters[adapter_name],
                step_name,
                operation_name,
                operation,
                options,
                &block
              )
            end
          end
        end
      end

      module InstanceMethods
        attr_reader :steps
        attr_reader :operations
        attr_reader :matcher

        def initialize(matcher: ResultMatcher, steps: (self.class.steps), **operations)
          @steps = steps.map { |step|
            operation = methods.include?(step.step_name) ? method(step.step_name) : operations[step.step_name]
            step.apply(operation: operation)
          }
          @operations = operations
          @matcher = matcher
        end

        def call(input, &block)
          assert_step_arity

          result = steps.inject(Dry::Monads.Right(input), :bind)

          if block
            matcher.(result, &block)
          else
            result.or { |step_failure|
              # Unwrap the value from the StepFailure and return it directly
              Dry::Monads.Left(step_failure.value)
            }
          end
        end

        def subscribe(listeners)
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
              step.apply(call_args: step_args[step.step_name])
            else
              step
            end
          }

          self.class.new(matcher: matcher, steps: new_steps, **operations)
        end

        private

        def respond_to_missing?(name, _include_private = false)
          steps.any? { |step| step.step_name == name }
        end

        def method_missing(name, *args, &block)
          step = steps.detect { |step| step.step_name == name }
          super unless step

          operation = operations[step.step_name]
          raise NotImplementedError, "no operation +#{step.operation_name}+ defined for step +#{step.step_name}+" unless operation

          operation.(*args, &block)
        end

        private

        # @param options [Hash] step arguments keyed by step name
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
end
