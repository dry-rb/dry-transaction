module Dry
  module Transaction
    module EnableInjection
      module Inject
        def resolve_operation(step, **operations)
          operation = operations[step.step_name] if operations[step.step_name].respond_to?(:call)
          operation || super
        end
      end

      module_function

      def call(transaction)
        transaction.include Dry::Transaction::EnableInjection::Inject
        transaction
      end
    end
  end
end
