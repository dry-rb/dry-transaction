module Dry
  module Transaction
    # A wrapper for storing together the step that failed
    # and value describing the failure.
    class StepFailure
      attr_reader :step
      attr_reader :value

      def initialize(step, value)
        @step = step
        @value = value
      end
    end
  end
end
