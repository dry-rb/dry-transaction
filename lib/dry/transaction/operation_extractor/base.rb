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
          op = extracted_operation
          raise error unless op
          op
        end

        def error
          raise NotImplementedError
        end

        def extracted_operation
          raise NotImplementedError
        end

        private

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
