module CallSheet
  module StepAdapters
    class Try < Base
      def call(*args, input)
        try! { operation.call(*args, input) }
      end
    end

    register :try, Try
  end
end
