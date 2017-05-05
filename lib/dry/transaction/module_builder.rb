module Dry
  class Transaction
    class ModuleBuilder
      def self.call(container, options)
        step_adapters = options.fetch(:step_adapters) { StepAdapters }

        steps_mod = Module.new do
          step_adapters.keys.each do |key|
            define_method(key) do |*args, &block|
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
              @steps << Step.new(step_adapter, step_name, operation_name, operation, options, &block)
            end
          end
        end

        Module.new do
          const_set :StepModule, steps_mod

          def self.included(klass)
            klass.instance_eval do
              @steps = []
            end

            klass.class_eval do
              def initialize(options = {})
                @matcher = options.fetch(:matcher) { ResultMatcher }
                @transaction = Transaction.new(self.class.instance_variable_get(:@steps), @matcher)
              end

              def method_missing(method, *args, &block)
                return super unless @transaction.respond_to?(method)
                @transaction.send(method, *args, &block)
              end
            end

            klass.extend const_get(:StepModule)
          end
        end
      end
    end
  end
end
