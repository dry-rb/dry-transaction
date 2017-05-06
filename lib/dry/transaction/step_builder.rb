module Dry
  class Transaction
    module StepBuilder
      def self.call(container, step_adapters, key, args, &block)
        step_adapter = step_adapters[key]
        step_name = args.first
        options = args.last.is_a?(::Hash) ? args.last : {}
        with = options.delete(:with)

        if with.respond_to?(:call)
          operation_name = step_name
          operation = StepDefinition.new(container, &with)
        else
          operation_name = with || step_name
          operation = container[operation_name]
        end

        Step.new(step_adapter, step_name, operation_name, operation, options, &block)
      end
    end
  end
end
