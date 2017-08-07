RSpec.describe "Transactions" do
  let(:dependencies) { {} }
  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
    Test::Process = Class.new do
      def call(input)
        input["name"].nil? ? raise(StandardError) : {name: input["name"], email: input["email"]}
      end

      def rollback(input)
        Dry::Monads::Left(input)
      end
    end

    Test::Verify = Class.new do
      def call(input)
        Dry::Monads::Right(input)
      end
    end

    Test::Validate = Class.new do
      def call(input)
        input[:email].nil? ? raise(Test::NotValidError, "email required") : input
      end
    end

    Test::Read = Class.new do
      def call(input)
        input
      end

      def rollback(input)
        Dry::Monads::Left(input)
      end
    end

    Test::Persist = Class.new do
      def call(input)
        Test::DB << input
      end

      def rollback(input)
        Test::DB.delete(input)
        Dry::Monads::Left(input)
      end
    end


    class Test::Container
      extend Dry::Container::Mixin
      register :process,  Test::Process.new
      register :verify,   Test::Verify.new
      register :validate, Test::Validate.new
      register :read, Test::Read.new
      register :persist,  Test::Persist.new
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

  context "execute rollback methods" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)

        rollback true
        map :read
        tee :persist
        map :process
      end.new(**dependencies)
    }

    let(:input) { {"name_2" => "Jane", "email_2" => "jane@doe.com"} }


    it "rollback to initial step and returns a Left" do
      expect(transaction.call(input)).to be_a Dry::Monads::Either::Left
    end

    it "no matter where it fails execute all rollback step backwards" do
      transaction.call(input)
      expect(Test::DB).to be_empty
    end
  end

  context "execute methods as normal" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)

        rollback true
        map :read
        tee :persist
        map :process
      end.new(**dependencies)
    }

    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }


    it "returns a Right" do
      expect(transaction.call(input)).to be_a Dry::Monads::Either::Right
    end

    it "executes steps as usual" do
      transaction.call(input)
      expect(Test::DB).to_not be_empty
    end
  end
end
