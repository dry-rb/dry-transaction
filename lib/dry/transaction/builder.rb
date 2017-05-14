require "dry/transaction/step_adapters"
require "dry/transaction/result_matcher"

module Dry
  class Transaction
    class Builder < Module
      attr_reader :container
      attr_reader :step_adapters

      attr_reader :class_mod

      ClassMethods = Class.new(Module)

      def initialize(container: nil, step_adapters: StepAdapters)
        @container = container
        @step_adapters = step_adapters

        @class_mod = ClassMethods.new
        define_class_mod
      end

      def included(klass)
        klass.extend(class_mod)
        klass.send(:include, InstanceMethods)
      end

      def define_class_mod
        class_mod.class_exec(container, step_adapters) do |container, step_adapters|
          def steps
            @steps ||= []
          end

          step_adapters.keys.each do |adapter_name|
            define_method(adapter_name) do |step_name, with: nil, **options, &block|
              operation = if container
                if with.respond_to?(:call)
                  operation_name = step_name
                  operation = StepDefinition.new(container, &with)
                else
                  operation_name = with || step_name
                  operation = container[operation_name]
                end
              end

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
        attr_reader :options, :matcher
        def initialize(**options)
          @options = options
          @matcher = options.fetch(:matcher) { ResultMatcher }
        end

        def steps
          self.class.steps
        end

        def call(input, &block)
          result = steps.inject(Dry::Monads.Right(input)) { |input, step|
            input.bind { |value|
              # We look for inject steps or local defined steps
              step_operation = methods.include?(step.step_name) ? method(step.step_name) : options[step.step_name]
              step = step.with_operation(step_operation) if step_operation
              step.(value)
            }
          }

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

        def respond_to_missing?(name, _include_private = false)
          steps.any? { |step| step.step_name == name }
        end

        def method_missing(name, *args, &block)
          step = steps.detect { |step| step.step_name == name }
          super unless step

          if step.operation
            step.operation.(*args, &block)
          else
            raise NotImplementedError, "no operation defined for step +#{step.step_name}+"
          end
        end
      end
    end
  end
end
