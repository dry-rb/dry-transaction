RSpec.describe "Transactions" do
  let(:dependencies) { {} }
  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
    Process = Struct.new("Process") do
      def call(input)
        {name: input["name"], email: input["email"]}
      end

      def rollback(input)
        {"name" => input[:name], "email" => input[:email]}
      end
    end

    Verify = Struct.new("Verify") do
      def call(input)
        Dry::Monads::Right(input)
      end
    end
    class Test::Container
      extend Dry::Container::Mixin
      register :process,  Process.new
      register :verify,   Verify.new
      register :validate, -> input { input[:email].nil? ? raise(Test::NotValidError, "email required") : input }
      register :persist,  -> input { Test::DB << input and true }
    end
  end

  context "rollback set to true" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)

        rollback true
        map :process
        step :verify
      end.new(**dependencies)
    }
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }


    it "raises error if any step doesn't have rollback method" do
      expect{
        transaction.call(input)
      }.to raise_error(Dry::Transaction::RollbackActionNotDefined)
    end
  end
end
