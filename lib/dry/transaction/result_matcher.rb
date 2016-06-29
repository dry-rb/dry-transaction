require "dry-result_matcher"

module Dry
  module Transaction
    ResultMatcher = Dry::ResultMatcher::Matcher.new(
      success: Dry::ResultMatcher::Case.new(
        match: -> result { result.right? },
        resolve: -> result { result.value },
      ),
      failure: Dry::ResultMatcher::Case.new(
        match: -> result, step_name = nil {
          if step_name
            result.left? && result.value.step_name == step_name
          else
            result.left?
          end
        },
        resolve: -> result { result.value.value },
      )
    )
  end
end
