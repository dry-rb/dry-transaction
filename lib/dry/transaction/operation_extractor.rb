# frozen_string_literal: true

require "dry/transaction/operation_extractor/injected"
require "dry/transaction/operation_extractor/container"

module Dry
  module Transaction
    class OperationExtractor
      class << self
        def call(transaction, step, operation)
          klass = get_extractor_class(transaction, operation, step)
          klass.call
        end

        private

        def get_extractor_class(transaction, operation, step)
          klass = self.const_get(step.source.to_s.capitalize)
          klass.new(transaction, operation, step.step_name)
        end
      end
    end
  end
end
