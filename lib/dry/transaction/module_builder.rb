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

          attr_reader :options, :steps

          def initialize(options = {})
            @options = options
            @matcher = options.fetch(:matcher) { ResultMatcher }
            @steps = self.class.instance_variable_get(:@_steps)
            @steps = overwrite_steps if options_include_step_key?
            @transaction = Transaction.new(@steps, @matcher)
          end

          def overwrite_steps
            options_keys = options.keys
            steps.each_with_object([]) do |step, new_steps|
              if options_keys.include?(step.operation_name)
                new_steps << step.with_new_opration(options[step.operation_name])
              else
                new_steps << step
              end
            end
          end

          def options_include_step_key?
            (steps.map(&:operation_name) & options.keys).any?
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
