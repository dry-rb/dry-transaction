# frozen_string_literal: true

module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Around
        include Dry::Monads[:result]

        def call(operation, options, args, &block)
          result = operation.(*args, &block)

          unless result.is_a?(Dry::Monads::Result)
            raise InvalidResultError, options[:step_name]
          end

          result
        end
      end

      register :around, Around.new
    end
  end
end
