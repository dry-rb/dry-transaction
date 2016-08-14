module Dry
  module Transaction
    # @api private
    class StepDefinition
      include Dry::Monads::Either::Mixin

      def initialize(container, &block)
        @container = container
        @block = block
        freeze
      end

      def call(*args)
        instance_exec(*args, &block)
      end

      private

      attr_reader :block
      attr_reader :container
    end
  end
end
