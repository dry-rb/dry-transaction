require "dry/monads/result"
require "dry/transaction/errors"

module Dry
  module Transaction
    class AroundStepFailure < StepFailure
      attr_reader :around_step

      def initialize(step, value)
        if value.is_a? Dry::Transaction::StepFailure
          @around_step = step
          @step = value.step
          @value = value.value
        else
          super(step, value)
        end
      end
    end

    class StepAdapters
      # @api private
      class Around
        include Dry::Monads::Result::Mixin

        def call(operation, options, args, &block)
          result = operation.(*args, &block)

          unless result.is_a?(Dry::Monads::Result)
            raise InvalidResultError.new(options[:step_name])
          end

          result
        end

        def failure_class
          AroundStepFailure
        end
      end

      register :around, Around.new
    end
  end
end
