require "dry/matcher"

module Dry
  module Transaction
    ResultMatcher = Dry::Matcher.new(
      success: Dry::Matcher::Case.new(
        match: -> result { result.right? },
        resolve: -> result { result.value! }
      ),
      failure: Dry::Matcher::Case.new(
        match: -> result, step_name = nil {
          if step_name
            result.left? && result.left.step.step_name == step_name
          else
            result.left?
          end
        },
        resolve: -> result { result.left.value }
      )
    )
  end
end
