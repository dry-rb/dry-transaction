module Dry
  module Transaction
    class StepFailure
      attr_reader :step_name
      attr_reader :value

      def initialize(step_name, value)
        @step_name = step_name
        @value = value
      end
    end
  end
end
