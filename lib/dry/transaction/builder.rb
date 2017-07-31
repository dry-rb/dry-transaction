require "dry/monads/either"
require "dry/transaction/step"
require "dry/transaction/dsl"
require "dry/transaction/instance_methods"
require "dry/transaction/operation_resolver"
require 'dry/core/class_attributes'

module Dry
  module Transaction
    class Builder < Module
      attr_reader :dsl_mod
      attr_reader :resolver_mod

      def initialize(container: nil, step_adapters:)
        @dsl_mod = DSL.new(step_adapters: step_adapters)
        @resolver_mod = OperationResolver.new(container)
      end

      def included(klass)
        klass.extend(dsl_mod)
        klass.send(:include, InstanceMethods)
        klass.send(:prepend, resolver_mod)
        klass.send(:extend, Dry::Core::ClassAttributes)
        klass.send(:include, Dry::Monads::Either::Mixin)
        klass.class_eval do
          defines :rollback

          rollback false
        end
      end
    end
  end
end
