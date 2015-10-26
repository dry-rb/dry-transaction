module CallSheet
  module StepAdapters
    class Raw < Base
      def call(*args, input)
        operation.call(input, *args)
      end
    end

    register :raw, Raw
  end
end
