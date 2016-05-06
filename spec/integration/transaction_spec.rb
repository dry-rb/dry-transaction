RSpec.describe "Transactions" do
  let(:transaction) {
    Dry.Transaction(container: container) do
      map :process
      step :verify
      try :validate, catch: Test::NotValidError
      tee :persist
    end
  }

  let(:container) {
    {
      process:  -> input { {name: input["name"], email: input["email"]} },
      verify:   -> input { Right(input) },
      validate: -> input { input[:email].nil? ? raise(Test::NotValidError, "email required") : input },
      persist:  -> input { Test::DB << input and true }
    }
  }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
  end

  context "successful" do
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

    it "calls the operations" do
      transaction.call(input)
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end

    it "returns a success" do
      expect(transaction.call(input)).to be_a Dry::Monads::Either::Right
    end

    it "wraps the result of the final operation" do
      expect(transaction.call(input).value).to eq(name: "Jane", email: "jane@doe.com")
    end

    it "can be called multiple times to the same effect" do
      transaction.call(input)
      transaction.call(input)

      expect(Test::DB[0]).to eq(name: "Jane", email: "jane@doe.com")
      expect(Test::DB[1]).to eq(name: "Jane", email: "jane@doe.com")
    end

    it "supports matching on success" do
      results = []

      transaction.call(input) do |m|
        m.success do |value|
          results << "success for #{value[:email]}"
        end
      end

      expect(results.first).to eq "success for jane@doe.com"
    end
  end

  context "failed in a try step" do
    let(:input) { {"name" => "Jane"} }

    it "does not run subsequent operations" do
      transaction.call(input)
      expect(Test::DB).to be_empty
    end

    it "returns a failure" do
      expect(transaction.call(input)).to be_a Dry::Monads::Either::Left
    end

    it "wraps the result of the failing operation" do
      expect(transaction.call(input).value).to be_a Test::NotValidError
    end

    it "supports matching on failure" do
      results = []

      transaction.call(input) do |m|
        m.failure do |value|
          results << "Failed: #{value}"
        end
      end

      expect(results.first).to eq "Failed: email required"
    end

    it "supports matching on specific step failures" do
      results = []

      transaction.call(input) do |m|
        m.failure :validate do |value|
          results << "Validation failure: #{value}"
        end
      end

      expect(results.first).to eq "Validation failure: email required"
    end

    it "supports matching on un-named step failures" do
      results = []

      transaction.call(input) do |m|
        m.failure :some_other_step do |value|
          results << "Some other step failure"
        end

        m.failure do |value|
          results << "Catch-all failure: #{value}"
        end
      end

      expect(results.first).to eq "Catch-all failure: email required"
    end
  end

  context "failed in a raw step" do
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

    before do
      container[:verify] = -> input { Left("raw failure") }
    end

    it "does not run subsequent operations" do
      transaction.call(input)
      expect(Test::DB).to be_empty
    end

    it "returns a failure" do
      expect(transaction.call(input)).to be_a Dry::Monads::Either::Left
    end

    it "returns the failing value from the operation" do
      expect(transaction.call(input).value).to eq "raw failure"
    end

    it "returns an object that quacks like expected" do
      result = transaction.call(input).value

      expect(Array(result)).to eq(['raw failure'])
    end

    it "does not allow to call private methods on the result accidently" do
      result = transaction.call(input).value

      expect { result.print('') }.to raise_error(NoMethodError)
    end
  end

  context "non-confirming raw step result" do
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

    before do
      container[:verify] = -> input { "failure" }
    end

    it "raises an exception" do
      expect { transaction.call(input) }.to raise_error(ArgumentError)
    end
  end
end
