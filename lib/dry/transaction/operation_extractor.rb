# frozen_string_literal: true

require "dry/transaction/operation_extractor/default"
require "dry/transaction/operation_extractor/injected"
require "dry/transaction/operation_extractor/container"

module Dry
  module Transaction
    class OperationExtractor
      class << self
        def call(transaction, name, operation)
          klass = get_extractor_class(transaction, operation, name)
          klass.call
        end

        private

        def get_extractor_class(transaction, operation, name)
          operation_source = operation.source ? operation.source : :default
          klass = self.const_get(operation_source.to_s.capitalize)
          klass.new(transaction, operation, name)
        end
      end
    end
  end
end
