require "dry/monads/result"
require "dry/transaction/errors"
require "dry/transaction/step_adapters/around"

module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Raw < Around
        def call(operation, options, args)
          super(operation, options, args, &nil)
        end
      end

      register :step, Raw.new
    end
  end
end
