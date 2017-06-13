require "dry/monads/either"
require "dry/matcher"
require "dry/matcher/either_matcher"

module Dry
  module Transaction
    module Operation
      def self.included(klass)
        klass.class_eval do
          include Dry::Monads::Either::Mixin
          include Dry::Matcher.for(:call, with: Dry::Matcher::EitherMatcher)
        end
      end
    end
  end
end
