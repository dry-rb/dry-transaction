require "forwardable"

module Dry
  module Transaction
    module StepAdapters
      @registry = {}

      class << self
        attr_reader :registry
        private :registry

        extend Forwardable
        def_delegators :registry, :[], :each

        # Register a step adapter.
        #
        # @param [Symbol] name the name to expose for adding steps to a transaction
        # @param klass the step adapter class
        #
        # @api public
        def register(name, klass)
          registry[name.to_sym] = klass
        end
      end
    end
  end
end
