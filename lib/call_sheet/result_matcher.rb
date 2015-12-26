module CallSheet
  class ResultMatcher
    attr_reader :result
    attr_reader :output

    def initialize(result)
      @result = result
    end

    def success(&block)
      return output unless result.is_a?(Kleisli::Either::Right)

      @output = block.call(result.value)
    end

    def failure(step_name = nil, &block)
      return output unless result.is_a?(Kleisli::Either::Left)

      if step_name.nil? || step_name == result.value.__step_name
        @output = block.call(result.value)
      end
    end
  end
end
