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

      attr_reader :operation, :arity

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

      # Ruby 2.7 gives a deprecation warning about passing a hash of parameters as the last argument
      # to a method. Ruby 3.0 outright disallows it. This checks for that condition, but explicitly
      # uses instance_of? rather than is_a? or kind_of?, because Hash like objects, specifically
      # HashWithIndifferentAccess objects are provided by Rails as controller parameters, and often
      # passed to dry-rb validators.
      # In this case, it's better to leave the object as it's existing type, rather than implicitly
      # convert it in to a hash with the double-splat (**) operator.
      def ruby_27_last_arg_hash?(args)
        kwargs = args.last
        kwargs.instance_of?(Hash) &&
          !kwargs.empty? &&
          Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7.0")
      end
    end
  end
end
