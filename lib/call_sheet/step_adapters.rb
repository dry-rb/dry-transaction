require "forwardable"

module CallSheet
  module StepAdapters
    @registry = {}

    class << self
      attr_reader :registry
      private :registry

      extend Forwardable
      def_delegators :registry, :[], :each

      def register(name, klass)
        registry[name.to_sym] = klass
      end
    end
  end
end
