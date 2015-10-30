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
    include Deterministic::Prelude::Result

    attr_reader :options # are we actually doing anything with this besides passing the container?
    attr_reader :container
    attr_reader :steps

    def initialize(options, &block)
      @options = options
      @container = options.fetch(:container)
      @steps = []

      instance_exec(&block)
    end

    StepAdapters.each do |adapter_name, adapter_class|
      define_method adapter_name do |step_name, options = {}|
        operation = options[:with].is_a?(Proc) ? options[:with] : container[options.fetch(:with, step_name)]
        steps << Step.new(step_name, adapter_class.new(operation, options))
      end
    end

    def call
      Transaction.new(steps)
    end
  end
end
