module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Tee
        include Dry::Monads::Result::Mixin

        def call(operation, _options, args)
          operation.(*args)
          Success(args[0])
        end
      end

      register :tee, Tee.new
    end
  end
end
