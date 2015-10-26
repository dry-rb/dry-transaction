module CallSheet
  module StepAdapters
    class Tee < Base
      def call(*args, input)
        operation.call(*args, input)
        Success(input)
      end
    end

    register :tee, Tee
  end
end
