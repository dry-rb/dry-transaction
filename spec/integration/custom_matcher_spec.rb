require "dry-matcher"
require "dry-monads"

RSpec.describe "Custom matcher" do
  let(:transaction) {
    Dry.Transaction(container: container, matcher: Test::CustomMatcher) do
      step :process
      step :validate
      step :persist
    end
  }

  let(:container) {
    {
      process: -> input { Dry::Monads.Right(name: input["name"], email: input["email"]) },
      validate: -> input { input[:email].nil? ? Dry::Monads.Left(:email_required) : Dry::Monads.Right(input) },
      persist:  -> input { Test::DB << input and Dry::Monads.Right(input) }
    }
  }

  before do
    Test::DB = []
    Test::QUEUE = []

    module Test
      CustomMatcher = Dry::Matcher.new(
        yep: Dry::Matcher::Case.new(
          match: -> result { result.right? },
          resolve: -> result { result.value }
        ),
        nup: Dry::Matcher::Case.new(
          match: -> result { result.left? },
          resolve: -> result { result.value.value }
        )
      )
    end
  end

  it "supports a custom matcher" do
    matches = -> m {
      m.yep { |v| "Yep! #{v[:email]}" }
      m.nup { |v| "Nup. #{v.to_s}" }
    }

    input = {"name" => "Jane", "email" => "jane@doe.com"}
    result = transaction.(input, &matches)
    expect(result).to eq "Yep! jane@doe.com"

    input = {"name" => "Jane"}
    result = transaction.(input, &matches)
    expect(result).to eq "Nup. email_required"
  end
end
