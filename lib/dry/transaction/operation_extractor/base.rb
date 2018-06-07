# frozen_string_literal: true

module Dry
  module Transaction
    class OperationExtractor
      class Base
        attr_reader :transaction, :operation, :name

        def initialize(transaction, operation, name)
          @transaction = transaction
          @operation = operation
          @name = name
        end

        def call
          raise NotImplementedError
        end

        private

        def function
          operation.function
        end

        def transaction_method
          transaction.method(name)
        end

        def transaction_methods
          @transaction_methods ||= transaction.methods + transaction.private_methods
        end
      end
    end
  end
end
