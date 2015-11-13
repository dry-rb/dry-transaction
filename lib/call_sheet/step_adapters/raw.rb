module CallSheet
  module StepAdapters
    # @api private
    class Raw < Base
      def call(*args, input)
        operation.call(*args, input)
      end
    end

    register :step, Raw
    register :raw, Raw
  end
end
