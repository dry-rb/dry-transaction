RSpec.describe "around steps" do
  include_context "db transactions"

  include Dry::Monads::Result::Mixin

  before do
    container.instance_exec do
      register :validate, -> input { Success(input) }

      register :persist_user do |user:, **other|
        self[:database] << [:user, user]
        Success(other)
      end

      register :persist_account do |account: |
        self[:database] << [:account, account]
        Success(true)
      end
    end
  end

  let(:transaction) do
    Class.new do
      include Dry::Transaction(container: Test::Container)

      step :validate
      around :transaction
      step :persist_user
      step :persist_account
      step :finalize
    end
  end

  let(:input) { { user: { name: "Jane" }, account: { balance: 0 } } }

  it "starts a transaction" do
    called = false

    finalize = -> x do
      called = true
      expect(database).to(be_in_transaction)
      Success(x)
    end

    result = transaction.new(finalize: finalize).call(input)
    expect(called).to be true
    expect(result).to eql(Success(true))
  end

  it "commits transactions" do
    transaction.new(finalize: -> x { Success(x) }).call(input)

    expect(database).to be_committed
    expect(database).not_to be_rolled_back
    expect(database).not_to be_in_transaction
    expect(database).to eql([[:user, name: "Jane"],
                             [:account, balance: 0]])
  end

  it "rolls back transactions on failure" do
    transaction.new(finalize: -> x { Failure(x) }).call(input)

    expect(database).to be_rolled_back
    expect(database).not_to be_in_transaction
    expect(database).not_to be_committed
    expect(database).to be_empty
  end

  it "rolls back transaction on exception" do
    uncaught = Class.new(StandardError)

    expect {
      transaction.new(finalize: -> x { raise uncaught }).call(input)
    }.to raise_error(uncaught)

    expect(database).to be_rolled_back
    expect(database).not_to be_in_transaction
    expect(database).not_to be_committed
    expect(database).to be_empty
  end
end
