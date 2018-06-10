RSpec.describe Dry::Transaction::Step do
  let(:step_adapter) { ->(step, input, *args) { step.operation.call(input, *args) } }
  let(:step_name) { :test }
  let(:operation_name) { step_name }

  subject(:step) {
    described_class.new(
      adapter: step_adapter,
      name: step_name,
      operation_name: operation_name,
      operation: operation,
      options: {}
    )
  }

  describe "#call" do
    let(:listener) do
      Class.new do
        attr_reader :started, :success, :failed

        def initialize
          @started = []
          @success = []
          @failed = []
        end

        def on_step(event)
          started << event[:step_name]
        end
        def on_step_succeeded(event)
          success << "succeded_#{event[:step_name]}"
        end
        def on_step_failed(event)
          failed << "failed_#{event[:step_name]}"
        end
      end.new
    end

    let(:input) { "input" }
    subject { step.call(input) }

    context "when operation succeeds" do
      let(:operation) { proc { |input| Dry::Monads.Success(input) } }

      it { is_expected.to be_success }

      it "publishes step_succeeded" do
        expect(listener).to receive(:on_step_succeeded).and_call_original
        step.subscribe(listener)
        subject

        expect(listener.success).to eq ['succeded_test']
      end
    end

    context "when operation starts" do
      let(:operation) { proc { |input| Dry::Monads.Success(input) } }

      it "publishes step" do
        expect(listener).to receive(:on_step).and_call_original
        step.subscribe(listener)
        subject

        expect(listener.started).to eq [:test]
      end
    end

    context "when operation fails" do
      let(:operation) { proc { |input| Dry::Monads.Failure("error") } }

      it { is_expected.to be_failure }

      it "wraps value in StepFailure" do
        aggregate_failures do
          expect(subject.failure).to be_a Dry::Transaction::StepFailure
          expect(subject.failure.value).to eq "error"
        end
      end

      it "publishes step_failed" do
        expect(listener).to receive(:on_step_failed).and_call_original
        step.subscribe(listener)
        subject

        expect(listener.failed).to eq ['failed_test']
      end
    end
  end

  describe "#with" do
    let(:operation) { proc { |a, b| a + b } }
    context "without arguments" do
      it "returns itself" do
        expect(step.with).to eq step
      end
    end

    context "with operation argument" do
      it "returns new instance with only operation changed" do
        new_operation = proc { |a,b| a * b }
        new_step = step.with(operation: new_operation)
        expect(new_step).to_not eq step
        expect(new_step.operation_name).to eq step.operation_name
        expect(new_step.operation).to_not eq step.operation
      end
    end

    context "with call_args argument" do
      let(:call_args) { [12] }
      it "returns new instance with only call_args changed" do
        new_step = step.with(call_args: call_args)
        expect(new_step).to_not eq step
        expect(new_step.operation_name).to eq step.operation_name
        expect(new_step.call_args).to_not eq step.call_args
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
