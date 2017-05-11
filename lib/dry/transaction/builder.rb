require "dry/transaction/step_adapters"
require "dry/transaction/result_matcher"

module Dry
  class Transaction
    class Builder < Module
      attr_reader :container
      attr_reader :step_adapters
      attr_reader :matcher

      attr_reader :class_mod
      attr_reader :instance_mod

      ClassMethods = Class.new(Module)

      def initialize(container: nil, step_adapters: StepAdapters, matcher: ResultMatcher)
        @container = container
        @step_adapters = step_adapters
        @matcher = matcher

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
                operation_name = with || step_name
                container[operation_name]
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
        attr_reader :options
        def initialize(**options)
          @options = options
        end

        def call(input)
          self.class.steps.inject(Dry::Monads.Right(input)) { |input, step|
            input.bind { |value|
              # We look for inject steps or local defined steps
              step_operation = options[step.step_name].nil?  ? method(step.step_name) : options[step.step_name]
              step = step.with_operation(step_operation) if step_operation
              step.(value)
            }
          }
        end

        def respond_to_missing?(name, _include_private = false)
          self.class.steps.any? { |step| step.step_name == name }
        end

        def method_missing(name, *args, &block)
          step = self.class.steps.detect { |step| step.step_name == name }
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
