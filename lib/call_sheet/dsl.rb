require "call_sheet/step"
require "call_sheet/step_adapters"
require "call_sheet/step_adapters/base"
require "call_sheet/step_adapters/map"
require "call_sheet/step_adapters/raw"
require "call_sheet/step_adapters/tee"
require "call_sheet/step_adapters/try"
require "call_sheet/transaction"

module CallSheet
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
      @container = options[:container]
      @steps = []

      instance_exec(&block)
    end

    StepAdapters.each do |adapter_name, adapter_class|
      define_method adapter_name do |step_name, options = {}|
        operation_value = options.fetch(:with, step_name)
        operation = operation_value.respond_to?(:call) ? operation_value : container[operation_value]
        steps << Step.new(step_name, adapter_class.new(operation, options))
      end
    end

    # @api private
    def call
      Transaction.new(steps)
    end
  end
end
