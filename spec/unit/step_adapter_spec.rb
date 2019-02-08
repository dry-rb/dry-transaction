require "dry/monads/result"

RSpec.describe Dry::Transaction::StepAdapter do
  include Dry::Monads::Result::Mixin
  
  describe "#inputs" do
    it "selects outputs for the steps listed in input option" do
      adapter = described_class.new(Proc.new {}, Proc.new {}, { input: [:foo, :bar] })
      outputs = [[:foo, Success("foo")], [:bar, Success("bar")], [:baz, Success("baz")]]

      expect(adapter.inputs(outputs)).to eq([Success("foo"), Success("bar")])
    end

    it "keeps the order specified in input option" do
      adapter = described_class.new(Proc.new {}, Proc.new {}, { input: [:bar, :foo] })
      outputs = [[:foo, Success("foo")], [:bar, Success("bar")]]

      expect(adapter.inputs(outputs)).to eq([Success("bar"), Success("foo")])
    end

    it "returns last output when input options is nil" do
      adapter = described_class.new(Proc.new {}, Proc.new {}, { })
      outputs = [[:foo, Success("foo")], [:bar, Success("bar")]]

      expect(adapter.inputs(outputs)).to eq([Success("bar")])
    end

    it "returns the empty list when input options is the empty list" do
      adapter = described_class.new(Proc.new {}, Proc.new {}, { input: [] })
      outputs = [[:foo, Success("foo")]]

      expect(adapter.inputs(outputs)).to eq([])
    end
  end

  describe "#inputs_arity" do
    it "returns length of input option" do
      adapter = described_class.new(Proc.new {}, Proc.new {}, { input: [:foo, :bar] })

      expect(adapter.inputs_arity).to eq(2)
    end

    it "returns 1 when no input option is given" do
      adapter = described_class.new(Proc.new {}, Proc.new {}, { })

      expect(adapter.inputs_arity).to eq(1)
    end
  end
end