# frozen_string_literal: true

require "dry/matcher"

module Dry
  module Transaction
    ResultMatcher = Dry::Matcher.new(
      success: Dry::Matcher::Case.new(
        match: -> result { result.success? },
        resolve: -> result { result.value! }
      ),
      failure: Dry::Matcher::Case.new(
        match: -> result, *step_names {
          if step_names.any?
            result.failure? && step_names.include?(result.failure.step.name)
          else
            result.failure?
          end
        },
        resolve: -> result { result.failure.value }
      )
    )
  end
end
