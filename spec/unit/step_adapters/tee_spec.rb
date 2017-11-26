RSpec.describe Dry::Transaction::StepAdapters::Tee, :adapter do

  subject { described_class.new }

  let(:operation) {
    -> (input) { input.upcase }
  }

  let(:options) { { step_name: "unit" } }

  describe "#call" do

    it "return a Success value" do
      expect(subject.(operation, options, ["input"])).to eql(Success("input"))
    end
  end
end
