module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Try
        def call(step, *args, input)
          unless step.options[:catch]
            raise ArgumentError, "+try+ steps require one or more exception classes provided via +catch:+"
          end

          Right(step.operation.call(*args, input))
        rescue *Array(step.options[:catch]) => e
          Left(e)
        end
      end

      register :try, Try.new
    end
  end
end
