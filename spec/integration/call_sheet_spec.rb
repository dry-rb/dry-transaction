RSpec.describe CallSheet do
  let(:call_sheet) {
    CallSheet(container: container) do
      map :process
      try :validate
      tee :persist
    end
  }

  let(:container) {
    {
      process:  -> input { {name: input["name"], email: input["email"]} },
      validate: -> input { input[:email].nil? ? raise(Test::NotValidError, "email required") : input },
      persist:  -> input { Test::DB << input and true }
    }
  }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
  end

  context "successful" do
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }
    let(:run_call_sheet) { call_sheet.call(input) }

    it "calls the operations" do
      run_call_sheet
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end

    it "returns a success" do
      expect(run_call_sheet).to be_success
    end

    it "wraps the result of the final operation" do
      expect(run_call_sheet.value).to eq(name: "Jane", email: "jane@doe.com")
    end

    it "supports pattern matching on success" do
      match = run_call_sheet.match do
        Success(s) { "Matched on success" }
        Failure(_) {}
      end

      expect(match).to eq "Matched on success"
    end
  end

  context "failed in a try step" do
    let(:input) { {"name" => "Jane"} }
    let(:run_call_sheet) { call_sheet.call(input) }

    it "does not run subsequent operations" do
      run_call_sheet
      expect(Test::DB).to be_empty
    end

    it "returns a failure" do
      expect(run_call_sheet).to be_failure
    end

    it "wraps the result of the failing operation" do
      expect(run_call_sheet.value).to be_a Test::NotValidError
    end

    it "supports pattern matching on failure" do
      match = run_call_sheet.match do
        Success(_) {}
        Failure(f) { "Matched on failure" }
      end

      expect(match).to eq "Matched on failure"
    end

    it "supports pattern matching on specific step failures" do
      match = run_call_sheet.match do
        Success(_) {}
        Failure(f, where { f == :validate }) { "Matched validate failure" }
        Failure(_) {}
      end

      expect(match).to eq "Matched validate failure"
    end
  end
end
