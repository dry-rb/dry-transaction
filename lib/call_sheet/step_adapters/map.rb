module CallSheet
  module StepAdapters
    # @api private
    class Map < Base
      def call(*args, input)
        Success(operation.call(input, *args))
      end
    end

    register :map, Map
  end
end
