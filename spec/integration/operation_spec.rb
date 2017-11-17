require "dry/transaction/operation"

RSpec.describe Dry::Transaction::Operation do
  subject(:operation) {
    Class.new do
      include Dry::Transaction::Operation

      def call(input)
        Success(input)
      end
    end.new
  }

  it "mixes in the Result monad constructors" do
    expect(operation.("hello")).to be_success
  end

  it "supports pattern matching when called with a block" do
    result = operation.("hello") do |m|
      m.success do |v|
        "Success: #{v}"
      end
      m.failure do |v|
        "Failure: #{v}"
      end
    end

    expect(result).to eq "Success: hello"
  end
end
