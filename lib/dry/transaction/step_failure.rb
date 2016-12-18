module Dry
  class Transaction
    # A wrapper for storing together the step that failed
    # and value describing the failure.
    class StepFailure
      attr_reader :step
      attr_reader :value

      # @param step [Step]
      # @param value [Object]
      def initialize(step, value)
        @step = step
        @value = value
      end
    end
  end
end
