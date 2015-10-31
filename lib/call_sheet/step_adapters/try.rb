module CallSheet
  module StepAdapters
    class Try < Base
      def initialize(*)
        super
        raise ArgumentError, "+try+ steps require one or more exception classes provided via +catch:+" unless options[:catch]
      end

      def call(*args, input)
        begin
          Success(operation.call(*args, input))
        rescue *Array(options[:catch]) => e
          Failure(e)
        end
      end
    end

    register :try, Try
  end
end
