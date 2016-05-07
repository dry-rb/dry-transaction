module Dry
  module Transaction
    class ResultMatcher
      attr_reader :result
      attr_reader :output

      def initialize(result)
        if result.respond_to?(:to_either)
          @result = result.to_either
        else
          @result = result
        end
      end

      def success(&block)
        return output unless result.right?

        @output = block.call(result.value)
      end

      def failure(step_name = nil, &block)
        return output unless result.left?

        if step_name.nil? || step_name == result.value.__step_name
          @output = block.call(result.value)
        end
      end
    end
  end
end
