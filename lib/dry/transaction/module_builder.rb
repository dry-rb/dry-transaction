require "dry/transaction/step_builder"

module Dry
  class Transaction
    module ModuleBuilder
      def self.call(container, options)
        step_adapters = options.fetch(:step_adapters) { StepAdapters }

        steps_mod = Module.new do
          step_adapters.keys.each do |key|
            define_method(key) do |*args, &block|
              @_steps << StepBuilder.call(container, step_adapters, key, args, &block)
            end
          end
        end

        Module.new do
          const_set :StepModule, steps_mod

          def self.included(klass)
            klass.instance_eval { @_steps = [] }
            klass.extend const_get(:StepModule)
          end

          def initialize(options = {})
            @matcher = options.fetch(:matcher) { ResultMatcher }
            @transaction = Transaction.new(self.class.instance_variable_get(:@_steps), @matcher)
          end

          def method_missing(method, *args, &block)
            return super unless @transaction.respond_to?(method)
            @transaction.send(method, *args, &block)
          end
        end
      end
    end
  end
end
