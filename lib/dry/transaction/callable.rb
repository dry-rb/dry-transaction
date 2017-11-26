module Dry
  module Transaction
    # @api private
    class Callable
      def self.[](callable)
        if callable.is_a?(self)
          callable
        elsif callable.nil?
          nil
        else
          new(callable)
        end
      end

      attr_reader :operation
      attr_reader :arity

      def initialize(operation)
        @operation = case operation
                     when Proc, Method
                       operation
                     else
                       operation.method(:call)
                     end

        @arity = @operation.arity
      end

      def call(*args, &block)
        if arity.zero?
          operation.(&block)
        else
          operation.(*args, &block)
        end
      end
    end
  end
end
