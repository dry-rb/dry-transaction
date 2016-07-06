RSpec.describe Dry::Transaction::StepAdapters::Map do

  subject { described_class.new }

  let(:operation) {
    -> (input) { input.upcase }
  }

  let(:step) {
    Dry::Transaction::Step.new(subject, :step, :step, operation, {})
  }

  describe "#call" do

    it "return a Right Monad" do
      expect(subject.call(step, 'input')).to be_a Dry::Monads::Either::Right
    end

    it "return the result of the operation as output" do
      expect(subject.call(step, 'input').value).to eql 'INPUT'
    end
  end
end
