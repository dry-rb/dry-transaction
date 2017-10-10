RSpec.describe "Passing additional arguments to step operations unsing step DSL inside transaction" do

  let(:with_call_args_step) {
    Class.new do
      include Dry::Transaction(container: Test::Container)
      map :process, with: :process, call_args: [{ city: 'Moscow' }]
    end.new
  }

  let(:without_call_args_step) {
    Class.new do
      include Dry::Transaction(container: Test::Container)
      step :process, with: :process
    end.new
  }

  let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
    module Test
      Container = {
        process:  -> input, args { args.merge({name: input["name"], email: input["email"]}) },
      }
    end
  end

  context "call_args provided for step" do
    let(:call_transaction) { with_call_args_step.call(input) }
    it "passes the arguments and calls the operations successfully" do
      expect(call_transaction).to eq Right({:city=>"Moscow", :name=>"Jane", :email=>"jane@doe.com"}) 
    end
  end

  context "call_args not provided for step" do
    let(:call_transaction) { without_call_args_step.call(input) }
    it "raises an ArgumentError" do
      expect { call_transaction }.to raise_error(ArgumentError)
    end
  end
end
