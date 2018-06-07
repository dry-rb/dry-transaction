# frozen_string_literal: true

require "dry/transaction/operation_extractor/base"

module Dry
  module Transaction
    class OperationExtractor
      class Injected < Base
        def call
          if function.respond_to?(:call)
            function
          elsif transaction_methods.include?(name)
            transaction_method
          else
            raise InvalidStepError.new(name)
          end
        end
      end
    end
  end
end
