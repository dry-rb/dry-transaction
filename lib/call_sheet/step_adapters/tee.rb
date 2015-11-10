module CallSheet
  module StepAdapters
    # @api private
    class Tee < Base
      def call(*args, input)
        operation.call(*args, input)
        Right(input)
      end
    end

    register :tee, Tee
  end
end
