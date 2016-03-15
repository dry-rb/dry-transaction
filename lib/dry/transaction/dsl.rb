require "dry/transaction/step"
require "dry/transaction/step_adapters"
require "dry/transaction/step_adapters/base"
require "dry/transaction/step_adapters/map"
require "dry/transaction/step_adapters/raw"
require "dry/transaction/step_adapters/tee"
require "dry/transaction/step_adapters/try"
require "dry/transaction/sequence"

module Dry
  module Transaction
    class DSL
      # @api private
      attr_reader :options

      # @api private
      attr_reader :container

      # @api private
      attr_reader :steps

      # @api private
      def initialize(options, &block)
        @options = options
        @container = options.fetch(:container)
        @steps = []

        instance_exec(&block)
      end

      StepAdapters.each do |adapter_name, adapter_class|
        define_method adapter_name do |step_name, options = {}|
          operation = container[options.fetch(:with, step_name)]
          steps << Step.new(step_name, adapter_class.new(operation, options))
        end
      end

      # @api private
      def call
        Sequence.new(steps)
      end
    end
  end
end
