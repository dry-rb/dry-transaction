# frozen_string_literal: true

module Dry
  module Transaction
    class OperationExtractor
      attr_reader :transaction, :name, :operation

      def initialize(transaction, name, operation)
        @transaction = transaction
        @name = name
        @operation = operation
      end

      def call
        source = operation.source
        function = operation.function

        case source
        when :injected
          injected_policy(function)
        when :container
          container_policy(function)
        when nil
          if transaction_methods.include?(name)
            transaction.method(name)
          else
            raise MissingStepError.new(name)
          end
        end
      end

      private

      def transaction_methods
        @transaction_methods ||= transaction.methods + transaction.private_methods
      end

      def injected_policy(function)
        if function.respond_to?(:call)
          function
        elsif transaction_methods.include?(name)
          transaction.method(name)
        else
          raise InvalidStepError.new(name)
        end
      end

      def container_policy(function)
        if transaction_methods.include?(name)
          transaction.method(name)
        elsif function.respond_to?(:call)
          function
        else
          raise InvalidStepError.new(name)
        end
      end
    end
  end
end
