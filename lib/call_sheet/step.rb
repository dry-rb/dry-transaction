require "wisper"
require "call_sheet/step_failure"

module CallSheet
  # @api private
  class Step
    include Wisper::Publisher

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
      args = (call_args << input)
      result = operation.call(*args)

      result.fmap { |value|
        broadcast :"#{step_name}_success", value
        value
      }.or { |value|
        broadcast :"#{step_name}_failure", *args, value
        Left(StepFailure.new(step_name, value))
      }
    end

    def arity
      operation.arity
    end
  end
end
