require "dry/monads/result"
require "dry/transaction/errors"

module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Around
        include Dry::Monads::Result::Mixin

        def call(operation, options, args, &block)
          result = operation.(*args, &block)

          unless result.is_a?(Dry::Monads::Result)
            raise InvalidResultError.new(options[:step_name])
          end

          result
        end
      end

      register :around, Around.new
    end
  end
end
