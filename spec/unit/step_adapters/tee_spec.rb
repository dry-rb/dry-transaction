RSpec.describe Dry::Transaction::StepAdapters::Tee do

  subject { described_class.new }

  let(:operation) {
    -> (input) { input.upcase }
  }

  let(:step) {
    Dry::Transaction::Step.new(subject, :step, :step, operation, {})
  }

  describe "#call" do

    it "return a Success value" do
      expect(subject.call(step, 'input')).to be_a Dry::Monads::Result::Success
    end

    it "return the original input as output" do
      expect(subject.call(step, 'input').value!).to eql 'input'
    end
  end
end
