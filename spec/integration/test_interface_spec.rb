require "dry/transaction/enable_injection"

RSpec.describe "Use test interface to fully replace operations with injected ones" do

  before do
    Test::DB = []
    Test::Container = container
    Dry::Transaction::EnableInjection.call(transaction_class)
  end

  let(:dependencies) { {process: ->input { {name: input["name"].upcase} }} }

  context "without container operation and local defined operation" do
    let(:container) {
      Class.new do
        extend Dry::Container::Mixin

        register :verify,  ->input { input[:name].to_s != "" ? Dry::Monads.Success(input) : Dry::Monads.Failure("no name") }
        register :persist, ->input { Test::DB << input and true }
      end
    }

    let(:transaction_class) {
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process
        step :verify, with: :verify
        tee :persist, with: :persist

        def proccess(input)
          { name: input["name"] }
        end
      end
    }

    context "when injecting operation" do
      it "use injected operation instead of local method" do
        transaction = transaction_class.new(**dependencies)
        transaction.call("name" => "Jane")
        expect(Test::DB).to include(name: "JANE")
      end
    end
  end

  context "with container operation" do
    let(:container) {
      Class.new do
        extend Dry::Container::Mixin

        register :process, ->input { {name: input["name"]} }
        register :verify,  ->input { input[:name].to_s != "" ? Dry::Monads.Success(input) : Dry::Monads.Failure("no name") }
        register :persist, ->input { Test::DB << input and true }
      end
    }

    let(:transaction_class) {
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process, with: :process
        step :verify, with: :verify
        tee :persist, with: :persist
      end
    }

    context "when injecting operation" do
      it "use injected operation instead of container base" do
        transaction = transaction_class.new(**dependencies)
        transaction.call("name" => "Jane")
        expect(Test::DB).to include(name: "JANE")
      end
    end
  end
end
