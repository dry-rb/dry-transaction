RSpec.describe "Transactions steps without arguments" do
  let(:dependencies) { {} }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = [{"name" => "Jane", "email" => "jane@doe.com"}]
    Test::Http = Class.new do
      def self.get
        "pong"
      end

      def self.post(value)
        Test::DB <<  value
      end
    end
    class Test::Container
      extend Dry::Container::Mixin
      register :fetch_data,     -> { Test::DB.delete_at(0) }, call: false
      register :call_outside,   -> { Test::Http.get }, call: false
      register :external_store, -> input { Test::Http.post(input) }
      register :process,        -> input { { name: input["name"], email: input["email"] } }
      register :validate,       -> input { input[:email].nil? ? raise(Test::NotValidError, "email required") : input }
      register :persist,        -> input { Test::DB << input and true }
    end
  end

  context "successful" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
          map :fetch_data, with: :fetch_data
          map :process, with: :process
          try :validate, with: :validate, catch: Test::NotValidError
          tee :persist, with: :persist
      end.new(**dependencies)
    }

    it "calls the operations" do
      transaction.call
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end

    it "returns a success" do
      expect(transaction.call()).to be_a Dry::Monads::Result::Success
    end

    it "wraps the result of the final operation" do
      expect(transaction.call().value!).to eq(name: "Jane", email: "jane@doe.com")
    end

    it "supports matching on success" do
      results = []

      transaction.call() do |m|
        m.success do |value|
          results << "success for #{value[:email]}"
        end

        m.failure { }
      end

      expect(results.first).to eq "success for jane@doe.com"
    end
  end

  context "using multiple tee step operators" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
          tee :call_outside, with: :call_outside
          map :fetch_data, with: :fetch_data
          map :process, with: :process
          try :validate, with: :validate, catch: Test::NotValidError
          tee :external_store, with: :external_store
      end.new(**dependencies)
    }

    it "calls the operations" do
      transaction.call
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end
  end

  context "not needing arguments in the middle of the transaction" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
          map :process, with: :process
          try :validate, with: :validate, catch: Test::NotValidError
          tee :call_outside, with: :call_outside
          tee :external_store, with: :external_store
      end.new(**dependencies)
    }
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

    it "calls the operations" do
      transaction.call(input)
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end
  end
end
