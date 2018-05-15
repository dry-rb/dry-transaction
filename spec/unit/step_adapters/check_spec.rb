RSpec.describe Dry::Transaction::StepAdapters::Check, :adapter do

  subject { described_class.new }

  let(:operation) {
    -> (input) { input == "right" }
  }

  let(:options) { { step_name: "unit" } }

  describe "#call" do

    it "returns the result of the operation as output" do
      expect(subject.(operation, options, ["right"])).to eql(Success("right"))
    end

    context "when check fails" do
      it "return a Failure" do
        expect(subject.(operation, options, ["wrong"])).to eql(Failure("wrong"))
      end
    end

    context "when operation return right monad" do
      let(:operation) {
        -> (input) { Success(true) }
      }

      it "return a Success" do
        expect(subject.(operation, options, ["input"])).to eql(Success("input"))
      end
    end

    context "when operation return failure monad" do
      let(:operation) {
        -> (input) { Failure(true) }
      }

      it "return a Failure" do
        expect(subject.(operation, options, ["input"])).to eql(Failure("input"))
      end
    end
  end
end
