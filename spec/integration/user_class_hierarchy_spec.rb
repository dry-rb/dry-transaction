RSpec.describe "dry transaction used with inheriting user classes" do
  let(:base_class) do
    Class.new do
      attr_reader :base_called

      def initialize(*_args)
        @base_called = true
      end
    end
  end

  let(:child_class) do
    Class.new(base_class) do
      include Dry::Transaction
    end
  end

  context "when user class inherits from another class" do
    subject { child_class.new }

    it "calls base class initializer" do
      expect(subject.base_called).to be true
    end
  end
end
