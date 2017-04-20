RSpec.describe Dry::Transaction::Step do
  let(:step_adapter) { ->(step, input, *args) { step.operation.call(input, *args) } }
  let(:step_name) { :test }
  let(:operation_name) { step_name }

  subject(:step) { described_class.new(step_adapter, step_name, operation_name, operation, {}) }

  describe "#call" do
    let(:listener) do
      Class.new do
        def test_success(*args); end
        alias_method :test_failure, :test_success
        alias_method :test_starting, :test_failure
      end.new
    end

    let(:input) { "input" }
    subject { step.call(input) }

    context "when operation succeeds" do
      let(:operation) { proc { |input| Dry::Monads::Either::Right.new(input) } }

      it { is_expected.to be_right }

      it "publishes success" do
        expect(listener).to receive(:test_success).with(input)
        step.subscribe(listener)
        subject
      end
    end

    context "when operation starts" do
      let(:operation) { proc { |input| Dry::Monads::Either::Right.new(input) } }

      it "publishes _starts" do
        expect(listener).to receive(:test_starts).with(input)
        step.subscribe(listener)
        subject
      end
    end

    context "when operation fails" do
      let(:operation) { proc { |input| Dry::Monads::Either::Left.new("error") } }

      it { is_expected.to be_left }

      it "wraps value in StepFailure" do
        aggregate_failures do
          expect(subject.value).to be_a Dry::Transaction::StepFailure
          expect(subject.value.value).to eq "error"
        end
      end

      it "publishes failure" do
        expect(listener).to receive(:test_failure).with(input, "error")
        step.subscribe(listener)
        subject
      end
    end
  end

  describe "#arity" do
    subject { step.arity }

    context "when operation is a proc" do
      let(:operation) { proc { |a, b| a + b } }
      it { is_expected.to eq 2 }
    end

    context "when operation is an object with call method" do
      let(:operation) do
        Class.new do
          def call(a, b, c)
            a + b + c
          end
        end.new
      end

      it { is_expected.to eq 3 }
    end
  end
end
