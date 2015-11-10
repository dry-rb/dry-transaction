module CallSheet
  class ResultMatcher
    attr_reader :result
    attr_reader :value

    def initialize(result)
      @result = result
      @value = result.value
    end

    def success(&block)
      block.call value if result.is_a?(Kleisli::Either::Right)
    end

    def failure(&block)
      block.call FailureMatcher.new(result) if result.is_a?(Kleisli::Either::Left)
    end

    class FailureMatcher
      attr_reader :result
      attr_reader :value

      def initialize(result)
        @result = result
        @value = result.value
      end

      def on(step_name, &block)
        if value.__step_name == step_name
          @matched = true
          block.call value
        end
      end

      def otherwise(&block)
        block.call value unless @matched
      end
    end
  end
end
