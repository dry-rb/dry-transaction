# frozen_string_literal: true

require "dry/transaction/operation_extractor/default"
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
          step_source = step.source ? step.source : :default
          klass = self.const_get(step_source.to_s.capitalize)
          klass.new(transaction, operation, step.step_name)
        end
      end
    end
  end
end
