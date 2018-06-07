# frozen_string_literal: true

require "dry/transaction/operation_extractor/base"

module Dry
  module Transaction
    class OperationExtractor
      class Container < Base
        def extracted_operation
          if transaction_methods.include?(name)
            transaction_method
          elsif operation.nil?
            raise MissingStepError.new(name)
          elsif operation.respond_to?(:call)
            operation
          end
        end
      end
    end
  end
end
