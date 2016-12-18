module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Try
        include Dry::Monads::Either::Mixin

        def call(step, input, *args)
          unless step.options[:catch]
            raise ArgumentError, "+try+ steps require one or more exception classes provided via +catch:+"
          end

          Right(step.operation.call(input, *args))
        rescue *Array(step.options[:catch]) => e
          e = step.options[:raise].new(e.message) if step.options[:raise]
          Left(e)
        end
      end

      register :try, Try.new
    end
  end
end
