RSpec.describe "Custom matcher" do
  let(:transaction) {
    Class.new do
      include Dry::Transaction(container: Test::Container)

      step :process
      step :validate, failure: :bad_value
      step :persist
    end.new(matcher: Test::CustomMatcher)
  }

  before do
    Test::DB = []
    Test::QUEUE = []

    module Test
      Container = {
        process: -> input { Dry::Monads.Right(name: input["name"], email: input["email"]) },
        validate: -> input { input[:email].nil? ? Dry::Monads.Left(:email_required) : Dry::Monads.Right(input) },
        persist:  -> input { Test::DB << input and Dry::Monads.Right(input) },
      }

      CustomMatcher = Dry::Matcher.new(
        yep: Dry::Matcher::Case.new(
          match: -> result { result.right? },
          resolve: -> result { result.value }
        ),
        nup: Dry::Matcher::Case.new(
          match: -> result, failure = nil {
            if failure
              result.left? && result.value.step.options[:failure] == failure
            else
              result.left?
            end
          },
          resolve: -> result { result.value.value }
        )
      )
    end
  end

  it "supports a custom matcher" do
    matches = -> m {
      m.yep { |v| "Yep! #{v[:email]}" }
      m.nup(:bad_value) { |v| "Nup. #{v.to_s}" }
    }

    input = {"name" => "Jane", "email" => "jane@doe.com"}
    result = transaction.(input, &matches)
    expect(result).to eq "Yep! jane@doe.com"

    input = {"name" => "Jane"}
    result = transaction.(input, &matches)
    expect(result).to eq "Nup. email_required"
  end
end
