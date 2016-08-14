RSpec.describe Dry::Transaction::StepDefinition do
  let(:container) do
    { test: -> input { "This is a test with input: #{input.inspect}" } }
  end

  let(:step_definition) do
    Dry::Transaction::StepDefinition.new(container) do |input|
      Right(container[:test].call(input))
    end
  end

  it { expect(step_definition).to be_kind_of(Dry::Monads::Either::Mixin) }

  describe '#initialize' do
    subject! { step_definition }

    it { is_expected.to be_frozen }
  end

  describe '#call' do
    let(:input) { { test: 'test' } }

    subject!(:result) { step_definition.call(input) }

    it do
      expect(result.value).to eq(
        "This is a test with input: {:test=>\"test\"}"
      )
    end
    it { is_expected.to be_a(Dry::Monads::Either::Right) }
  end
end
