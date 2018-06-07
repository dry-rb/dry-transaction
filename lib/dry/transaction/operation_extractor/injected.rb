# frozen_string_literal: true

require "dry/transaction/operation_extractor/base"

module Dry
  module Transaction
    class OperationExtractor
      class Injected < Base
        def extracted_operation
          if operation.respond_to?(:call)
            operation
          elsif transaction_methods.include?(name)
            transaction_method
          elsif operation.nil?
            raise MissingStepError.new(name)
          end
        end
      end
    end
  end
end
