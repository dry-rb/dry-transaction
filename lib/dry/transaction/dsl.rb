require "dry/transaction/result_matcher"
require "dry/transaction/step"
require "dry/transaction/step_adapters"
require "dry/transaction/sequence"

module Dry
  module Transaction
    # @api private
    class DSL < BasicObject
      attr_reader :container
      attr_reader :step_adapters
      attr_reader :steps
      attr_reader :matcher

      def initialize(options, &block)
        @container = options.fetch(:container)
        @step_adapters = options.fetch(:step_adapters) { StepAdapters }
        @steps = []
        @matcher = options.fetch(:matcher) { ResultMatcher }

        instance_eval(&block)
      end

      def respond_to_missing?(method_name)
        step_adapters.key?(method_name)
      end

      def method_missing(method_name, *args, &cb)
        return super unless step_adapters.key?(method_name)

        step_adapter = step_adapters[method_name]
        step_name = args.first
        options = args.last.is_a?(::Hash) ? args.last : {}
        options[:λ] = cb unless cb.nil?
        operation_name = options.delete(:with) || step_name
        operation = container[operation_name]

        steps << Step.new(step_adapter, step_name, operation_name, operation, options)
      end

      def call
        Sequence.new(steps, matcher)
      end
    end
  end
end
