RSpec.describe Dry::Transaction::StepAdapters::Raw do

  subject { described_class.new }

  let(:operation) {
    -> (input) { input.upcase }
  }

  let(:step) {
    Dry::Transaction::Step.new(subject, :step, :step, operation, {})
  }

  describe "#call" do

    context "when the result of the operation is NOT a Dry::Monads::Either" do

      it "raises an ArgumentError" do
        expect do
          subject.call(step, 'input')
        end.to raise_error(ArgumentError)
      end
    end

    context "when the result of the operation is a Left Monad" do
      let(:operation) {
        -> (input) { Left(input.upcase) }
      }

      it "return a Left Monad" do
        expect(subject.call(step, 'input')).to be_a Dry::Monads::Either::Left
      end

      it "return the result of the operation as output" do
        expect(subject.call(step, 'input').value).to eql 'INPUT'
      end
    end

    context "when the result of the operation is a Right Monad" do
      let(:operation) {
        -> (input) { Right(input.upcase) }
      }

      it "return a Right Monad" do
        expect(subject.call(step, 'input')).to be_a Dry::Monads::Either::Right
      end

      it "return the result of the operation as output" do
        expect(subject.call(step, 'input').value).to eql 'INPUT'
      end
    end
  end
end
