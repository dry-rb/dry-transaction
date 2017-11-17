RSpec.describe "Passing additional arguments to step operations" do
  let(:call_transaction) { transaction.with_step_args(step_options).call(input) }

  let(:transaction) {
    Class.new do
      include Dry::Transaction(container: Test::Container)

      map :process, with: :process
      try :validate, with: :validate, catch: Test::NotValidError
      tee :persist, with: :persist
    end.new
  }

  let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
    module Test
      Container = {
        process:  -> input { {name: input["name"], email: input["email"]} },
        validate: -> input, allowed { !input[:email].include?(allowed) ? raise(Test::NotValidError, "email not allowed") : input },
        persist:  -> input { Test::DB << input and true }
      }
    end
  end

  context "required arguments provided" do
    let(:step_options) { {validate: ["doe.com"]} }

    it "passes the arguments and calls the operations successfully" do
      expect(call_transaction).to be_a Dry::Monads::Result::Success
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
