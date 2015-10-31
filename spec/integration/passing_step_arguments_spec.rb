RSpec.describe "Passing additional arguments to step operations" do
  let(:run_call_sheet) { call_sheet.call(input, step_options) }

  let(:call_sheet) {
    CallSheet(container: container) do
      map :process
      try :validate, catch: Test::NotValidError
      tee :persist
    end
  }

  let(:container) {
    {
      process:  -> input { {name: input["name"], email: input["email"]} },
      validate: -> allowed, input { !input[:email].include?(allowed) ? raise(Test::NotValidError, "email not allowed") : input },
      persist:  -> input { Test::DB << input and true }
    }
  }

  let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
  end

  context "required arguments provided" do
    let(:step_options) { {validate: ["doe.com"]} }

    it "passes the arguments and calls the operations successfully" do
      expect(run_call_sheet).to be_success
    end
  end

  context "required arguments not provided" do
    let(:step_options) { {} }

    it "raises an ArgumentError" do
      expect { run_call_sheet }.to raise_error(ArgumentError)
    end
  end

  context "spurious arguments provided" do
    let(:step_options) { {validate: ["doe.com"], bogus: ["not matching any step"]} }

    it "raises an ArgumentError" do
      expect { run_call_sheet }.to raise_error(ArgumentError)
    end
  end
end
