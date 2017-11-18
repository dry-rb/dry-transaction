RSpec.describe Dry::Transaction::StepAdapters::Around do
  subject { described_class.new }

  let(:operation) {
    -> (input, &block) { block.(Success(input.upcase)) }
  }

  let(:step) {
    Dry::Transaction::Step.new(subject, :step, :step, operation, {})
  }

  let(:continue) do
    -> (input) { input.fmap { |v| v + " terminated" } }
  end

  describe "#call" do
    context "when the result of the operation is NOT a Dry::Monads::Result" do
      let(:continue) do
        -> (input) { "plain string" }
      end

      let(:operation) {
        -> (input, &block) { block.(input.upcase) }
      }

      it "raises an ArgumentError" do
        expect do
          subject.call(step, 'input', &continue)
        end.to raise_error(ArgumentError, /must return a Result object/)
      end
    end

    context "passing a block" do
      let(:operation) { -> (input, &block) { block.(Success(input.upcase)) } }

      it "return a Success value" do
        expect(subject.call(step, 'input', &continue)).to be_a Dry::Monads::Result::Success
      end

      it "yields a block" do
        result = subject.call(step, "input", &continue)

        expect(result).to eql(Success("INPUT terminated"))
      end
    end

    context "when the result of the operation is a Failure value" do
      let(:operation) {
        -> (input, &block) { block.(Failure(input.upcase)) }
      }

      it "return a Failure value" do
        expect(subject.call(step, 'input', &continue)).to be_a Dry::Monads::Result::Failure
      end

      it "return the result of the operation as output" do
        expect(subject.call(step, 'input', &continue).failure).to eql 'INPUT'
      end
    end
  end
end
