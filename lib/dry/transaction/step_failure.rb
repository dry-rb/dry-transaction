module Dry
  module Transaction
    class StepFailure < BasicObject
      attr_reader :__step_name

      def initialize(step_name, object)
        @__step_name = step_name
        @__object = object
      end

      def method_missing(name, *args, &block)
        @__object.public_send(name, *args, &block)
      end

      def respond_to_missing?(*args)
        @__object.respond_to?(*args)
      end

      def ==(other)
        @__object == other
      end
    end
  end
end
