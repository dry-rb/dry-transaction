module CallSheet
  module StepAdapters
    class Base
      include Deterministic::Prelude::Result

      attr_reader :operation
      attr_reader :options

      def initialize(operation, options)
        @operation = operation
        @options = options
      end

      def arity
        operation.is_a?(Proc) ? operation.arity : operation.method(:call).arity
      end
    end
  end
end
