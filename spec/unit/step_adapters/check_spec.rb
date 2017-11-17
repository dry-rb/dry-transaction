RSpec.describe Dry::Transaction::StepAdapters::Check do

  subject { described_class.new }

  let(:operation) {
    -> (input) { input == 'input' }
  }

  let(:step) {
    Dry::Transaction::Step.new(subject, :step, :step, operation, {})
  }

  describe "#call" do

    it "return a Right Monad" do
      expect(subject.call(step, 'input')).to be_a Dry::Monads::Result::Success
    end

    it "return the result of the operation as output" do
      expect(subject.call(step, 'input').value).to eql 'input'
    end

    context "when check fail" do
      it "return a Left Monad" do
        expect(subject.call(step, 'wrong')).to be_a Dry::Monads::Either::Failure
      end

      it "return the result of the operation as output" do
        expect(subject.call(step, 'input').value).to eql 'input'
      end
    end

    context "when operation return right monad" do
      let(:operation) {
        -> (input) { Success(true) }
      }

      it "return a Right Monad" do
        expect(subject.call(step, 'input')).to be_a Dry::Monads::Result::Success
      end
    end

    context "when operation return left monad" do
      let(:operation) {
        -> (input) { Failure(true) }
      }

      it "return a Left Monad" do
        expect(subject.call(step, 'input')).to be_a Dry::Monads::Either::Failure
      end
    end
  end
end
