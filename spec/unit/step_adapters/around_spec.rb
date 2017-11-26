RSpec.describe Dry::Transaction::StepAdapters::Around, :adapter do
  subject { described_class.new }

  let(:operation) {
    -> (input, &block) { block.(Success(input.upcase)) }
  }

  let(:options) { { step_name: "unit" } }

  let(:continue) do
    -> (input) { input.fmap { |v| v + " terminated" } }
  end

  describe "#call" do
    context "when the result of the operation is NOT a Dry::Monads::Result" do
      let(:continue) do
        -> (input) { "plain string" }
      end

      it "raises an InvalidResultError" do
        expect {
          subject.(operation, options, ["input"], &continue)
        }.to raise_error(
               Dry::Transaction::InvalidResultError,
               "step +unit+ must return a Result object"
             )
      end
    end

    context "passing a block" do
      it "returns a Success value with result from block" do
        expect(subject.(operation, options, ["input"], &continue)).to eql(Success("INPUT terminated"))
      end
    end

    context "when the result of the operation is a Failure value" do
      let(:operation) {
        -> (input, &block) { block.(Failure(input.upcase)) }
      }

      it "return a Failure value" do
        expect(subject.(operation, options, ["input"], &continue)).to eql(Failure("INPUT"))
      end
    end
  end
end
