require "call_sheet/step_failure"

module CallSheet
  class Step
    include Deterministic::Prelude::Result

    attr_reader :step_name
    attr_reader :operation
    attr_reader :call_args

    def initialize(step_name, operation, call_args = [])
      @step_name = step_name
      @operation = operation
      @call_args = call_args
    end

    def with_call_args(*call_args)
      self.class.new(step_name, operation, call_args)
    end

    def call(input)
      result = operation.call(*(call_args << input))
      result.map_err { |v| Failure(StepFailure.new(step_name, v)) }
    end

    def arity
      operation.arity
    end
  end
end
