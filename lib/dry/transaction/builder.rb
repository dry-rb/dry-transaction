require "dry/transaction/result_matcher"
require "dry/transaction/step"
require "dry/transaction/instance_methods"
require "dry/transaction/operation_resolver"

module Dry
  module Transaction
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
              operation_name = with || step_name
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
    end
  end
end
