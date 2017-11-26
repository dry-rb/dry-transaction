module Dry
  module Transaction
    class InvalidStepError < ArgumentError
      def initialize(step_name)
        super("step +`#{step_name}`+ must respond to `#call`")
      end
    end

    class MissingStepError < ArgumentError
      def initialize(step_name)
        super("Definition for step +`#{step_name}`+ is missing")
      end
    end

    class InvalidResultError < ArgumentError
      def initialize(step_name)
        super("step +#{step_name}+ must return a Result object")
      end
    end

    class MissingCatchListError < ArgumentError
      def initialize(step_name)
        super("step +#{step_name}+ requires one or more exception classes provided via +catch:+")
      end
    end
  end
end
