RSpec.describe Dry::Transaction::StepAdapters::Try do

  subject { described_class.new }

  let(:operation) {
    -> (input) {
      raise(Test::NotValidError, 'not a string') unless input.is_a? String
      input.upcase
    }
  }

  let(:step) {
    Dry::Transaction::Step.new(subject, :step, :step, operation, options)
  }

  let(:options) { { catch: Test::NotValidError } }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::BetterNamingError = Class.new(StandardError)
  end

  describe "#call" do

    context "without the :catch option" do
      let(:options) { { } }

      it "raises an ArgumentError" do
        expect do
          subject.call(step, {})
        end.to raise_error(ArgumentError)
      end
    end

    context "with the :catch option" do

      context "when the error was raised" do

        it "return a Left Monad" do
          expect(subject.call(step, 1234)).to be_a Dry::Monads::Either::Left
        end

        it "return the raised error as output" do
          result = subject.call(step, 1234)
          expect(result.value).to be_a Test::NotValidError
          expect(result.value.message).to eql 'not a string'
        end

        context "when using the :raise option" do
          let(:options) {
            {
              catch: Test::NotValidError,
              raise: Test::BetterNamingError
            }
          }

          it "return a Left Monad" do
            expect(subject.call(step, 1234)).to be_a Dry::Monads::Either::Left
          end

          it "return the error specified by :raise as output" do
            result = subject.call(step, 1234)
            expect(result.value).to be_a Test::BetterNamingError
            expect(result.value.message).to eql 'not a string'
          end
        end
      end

      context "when the error was NOT raised" do

        it "return a Right Monad" do
          expect(subject.call(step, 'input')).to be_a Dry::Monads::Either::Right
        end

        it "return the result of the operation as output" do
          expect(subject.call(step, 'input').value).to eql 'INPUT'
        end

        context "when using the :raise option" do
          let(:options) {
            {
              catch: Test::NotValidError,
              raise: Test::BetterNamingError
            }
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
  end
end
