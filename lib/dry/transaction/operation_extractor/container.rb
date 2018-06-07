# frozen_string_literal: true

require "dry/transaction/operation_extractor/base"

module Dry
  module Transaction
    class OperationExtractor
      class Container < Base

        def extracted_operation
          if transaction_methods.include?(name)
            transaction_method
          elsif function.respond_to?(:call)
            function
          end
        end

        def error
          InvalidStepError.new(name)
        end
      end
    end
  end
end
