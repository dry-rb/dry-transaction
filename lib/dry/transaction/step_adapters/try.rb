module Dry
  module Transaction
    module StepAdapters
      # @api private
      class Try < Base
        def initialize(*)
          super
          raise ArgumentError, "+try+ steps require one or more exception classes provided via +catch:+" unless options[:catch]
        end

        def call(*args, input)
          Right(operation.call(*args, input))
        rescue *Array(options[:catch]) => e
          Left(e)
        end
      end

      register :try, Try
    end
  end
end
