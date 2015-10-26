module CallSheet
  module StepAdapters
    class Map < Base
      def call(*args, input)
        Success(operation.call(input, *args))
      end
    end

    register :map, Map
  end
end
