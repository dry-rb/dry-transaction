require "dry/monads/result"
require "dry/matcher"
require "dry/matcher/result_matcher"

module Dry
  module Transaction
    module Operation
      def self.included(klass)
        klass.class_eval do
          include Dry::Monads::Result::Mixin
          include Dry::Matcher.for(:call, with: Dry::Matcher::ResultMatcher)
        end
      end
    end
  end
end
