module Dry
  module Transaction
    class DSL < Module
      def initialize(step_adapters:)
        @step_adapters = step_adapters

        define_steps
        define_dsl
      end

      def inspect
        "Dry::Transaction::DSL(#{@step_adapters.keys.sort.join(', ')})"
      end

      private

      def define_steps
        module_eval do
          define_method(:steps) do
            @steps ||= []
          end
        end
      end

      def define_dsl
        module_exec(@step_adapters) do |step_adapters|
          step_adapters.keys.each do |adapter_name|
            define_method(adapter_name) do |step_name, with: nil, **options|
              operation_name = with || step_name

              steps << Step.new(
                step_adapters[adapter_name],
                step_name,
                operation_name,
                nil, # operations are resolved only when transactions are instantiated
                options,
              )
            end
          end
        end
      end
    end
  end
end
