module Dry
  module Transaction
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
