RSpec.describe Dry::Transaction::StepAdapters::Raw do

  subject { described_class.new }

  let(:operation) {
    -> (input) { input.upcase }
  }

  let(:step) {
    Dry::Transaction::Step.new(subject, :step, :step, operation, {})
  }

  describe "#call" do

    context "when the result of the operation is NOT a Dry::Monads::Result" do

      it "raises an ArgumentError" do
        expect do
          subject.call(step, 'input')
        end.to raise_error(ArgumentError)
      end
    end

    context "when the result of the operation is a Failure value" do
      let(:operation) {
        -> (input) { Failure(input.upcase) }
      }

      it "return a Failure value" do
        expect(subject.call(step, 'input')).to be_a Dry::Monads::Result::Failure
      end

      it "return the result of the operation as output" do
        expect(subject.call(step, 'input').left).to eql 'INPUT'
      end
    end

    context "when the result of the operation is a Success value" do
      let(:operation) {
        -> (input) { Success(input.upcase) }
      }

      it "return a Success value" do
        expect(subject.call(step, 'input')).to be_a Dry::Monads::Result::Success
      end

      it "return the result of the operation as output" do
        expect(subject.call(step, 'input').value!).to eql 'INPUT'
      end
    end
  end
end
