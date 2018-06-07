# frozen_string_literal: true

require "dry/transaction/operation_extractor/base"

module Dry
  module Transaction
    class OperationExtractor
      class Default < Base

        def extracted_operation
          transaction_method if transaction_methods.include?(name)
        end

        def error
          MissingStepError.new(name)
        end
      end
    end
  end
end
