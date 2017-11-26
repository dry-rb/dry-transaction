RSpec.describe Dry::Transaction::StepAdapters::Raw, adapter: true do

  subject { described_class.new }

  let(:options) { { step_name: "unit" } }

  describe "#call" do

    context "when the result of the operation is NOT a Dry::Monads::Result" do

      let(:operation) {
        -> (input) { input.upcase }
      }

      it "raises an InvalidResultError" do
        expect {
          subject.(operation, options, "input")
        }.to raise_error(
               Dry::Transaction::InvalidResultError,
               "step +unit+ must return a Result object"
             )
      end
    end

    context "when the result of the operation is a Success value" do

      let(:operation) {
        -> (input) { Success(input.upcase) }
      }

      it "return a Success value" do
        expect(subject.(operation, options, "input")).to eql(Success("INPUT"))
      end
    end
  end
end
