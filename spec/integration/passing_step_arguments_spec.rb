RSpec.describe "Passing additional arguments to step operations" do
  let(:call_transaction) { transaction.step_args(step_options).call(input) }

  let(:transaction) {
    Dry.Transaction(container: container) do
      map :process
      try :validate, catch: Test::NotValidError
      tee :persist
    end
  }

  let(:container) {
    {
      process:  -> input { {name: input["name"], email: input["email"]} },
      validate: -> input, allowed { !input[:email].include?(allowed) ? raise(Test::NotValidError, "email not allowed") : input },
      persist:  -> input { Test::DB << input and true }
    }
  }

  let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
  end

  context "required arguments provided" do
    let(:step_options) { {validate: ["doe.com"]} }

    it "passes the arguments and calls the operations successfully" do
      expect(call_transaction).to be_a Dry::Monads::Either::Right
    end
  end

  context "required arguments not provided" do
    let(:step_options) { {} }

    it "raises an ArgumentError" do
      expect { call_transaction }.to raise_error(ArgumentError)
    end
  end

  context "spurious arguments provided" do
    let(:step_options) { {validate: ["doe.com"], bogus: ["not matching any step"]} }

    it "raises an ArgumentError" do
      expect { call_transaction }.to raise_error(ArgumentError)
    end
  end
end
