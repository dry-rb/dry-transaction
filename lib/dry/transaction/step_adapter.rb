require "dry/transaction/callable"

module Dry
  module Transaction
    # @api private
    class StepAdapter
      def self.[](adapter, operation, options)
        if adapter.is_a?(self)
          adapter.with(operation, options)
        else
          new(adapter, operation, options)
        end
      end

      attr_reader :adapter
      attr_reader :operation
      attr_reader :options

      def initialize(adapter, operation, options)
        @adapter = case adapter
                   when Proc, Method
                     adapter
                   else
                     adapter.method(:call)
                   end

        @operation = Callable[operation]

        @options = options

        @yields = @adapter.
                    parameters.
                    any? { |type, _| type == :block }
      end

      def yields?
        @yields
      end

      def call(args, &block)
        adapter.(operation, options, args, &block)
      end

      def with(operation = self.operation, new_options = {})
        self.class.new(adapter, operation, options.merge(new_options))
      end
    end
  end
end
