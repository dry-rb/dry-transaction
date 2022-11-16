# frozen_string_literal: true

require "dry/matcher/result_matcher"

module Dry
  module Transaction
    module Operation
      def self.included(klass)
        klass.class_eval do
          include Dry::Monads[:result]
          include Dry::Matcher.for(:call, with: Dry::Matcher::ResultMatcher)
        end
      end
    end
  end
end
