RSpec.describe Dry::Transaction::StepAdapters::Try do

  subject { described_class.new }

  let(:operation) {
    -> (input) {
      raise(Test::NotValidError, 'not a string') unless input.is_a? String
      input.upcase
    }
  }

  let(:options) { { catch: Test::NotValidError, step_name: "unit" } }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::BetterNamingError = Class.new(StandardError)
  end

  describe "#call" do

    context "without the :catch option" do
      let(:options) { { step_name: "unit" } }

      it "raises an ArgumentError" do
        expect {
          subject.(operation, options, ["something"])
        }.to raise_error(
               Dry::Transaction::MissingCatchListError,
               "step +unit+ requires one or more exception classes provided via +catch:+"
             )
      end
    end

    context "with the :catch option" do

      context "when the error was raised" do

        it "returns a Failure value" do
          expect(subject.(operation, options, [1234])).to be_a_failure
        end

        it "returns the raised error as output" do
          result = subject.(operation, options, [1234])
          expect(result.failure).to be_a Test::NotValidError
          expect(result.failure.message).to eql("not a string")
        end

        context "when using the :raise option" do
          let(:options) {
            {
              catch: Test::NotValidError,
              raise: Test::BetterNamingError
            }
          }

          it "returns a Failure value" do
            expect(subject.(operation, options, [1234])).to be_a_failure
          end

          it "returns the error specified by :raise as output" do
            result = subject.(operation, options, [1234])
            expect(result.failure).to be_a Test::BetterNamingError
            expect(result.failure.message).to eql("not a string")
          end
        end
      end

      context "when the error was NOT raised" do

        it "returns a Success value" do
          expect(subject.(operation, options, ["input"])).to eql(Success("INPUT"))
        end

        context "when using the :raise option" do
          let(:options) {
            {
              catch: Test::NotValidError,
              raise: Test::BetterNamingError
            }
          }

          it "returns a Success value" do
            expect(subject.(operation, options, ["input"])).to  eql(Success("INPUT"))
          end
        end
      end
    end
  end
end
