# frozen_string_literal: true

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
        elsif ruby_27_last_arg_hash?(args)
          *prefix, last = args
          operation.(*prefix, **last, &block)
        else
          operation.(*args, &block)
        end
      end

      private

      def ruby_27_last_arg_hash?(args)
        args.last.instance_of?(Hash) && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7.0")
      end
    end
  end
end
