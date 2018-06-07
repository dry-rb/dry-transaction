# frozen_string_literal: true

require "dry/transaction/operation_extractor/base"

module Dry
  module Transaction
    class OperationExtractor
      class Default < Base
        def call
          if transaction_methods.include?(name)
            transaction_method
          else
            raise MissingStepError.new(name)
          end
        end
      end
    end
  end
end
