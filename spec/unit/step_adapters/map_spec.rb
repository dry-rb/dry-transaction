RSpec.describe Dry::Transaction::StepAdapters::Map, :adapter do

  subject { described_class.new }

  let(:options) { {} }

  let(:operation) {
    -> (input) { input.upcase }
  }

  describe "#call" do
    it "return a Success value" do
      expect(subject.(operation, options, 'input')).to eql(Success('INPUT'))
    end
  end
end
