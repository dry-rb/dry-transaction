RSpec.describe "using inline procs with raw steps" do
  let(:call_sheet) {
    CallSheet(container: container) do
      map :process
      raw :validate, with: -> input { input[:email].nil? ? Failure("email required") : Success(input) }
    end
  }

  let(:container) { {process:  -> input { {name: input["name"], email: input["email"]} }} }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
  end

  context "inline step returns Success" do
    it "calls all the operations" do
      input = {"name" => "Jane", "email" => "jane@doe.com"}
      expect(call_sheet.call(input)).to be_success
    end
  end

  context "inline step returns Failure" do
    let(:input) { {"name" => "Jane"} }

    it "stops running the step operations and returns the failure" do
      expect(call_sheet.call(input)).to be_failure
    end

    it "supports pattern matching on the failed step name" do
      match = call_sheet.call(input).match do
        Success(_) {}
        Failure(f, where { f == :validate }) { "Matched validate failure" }
        Failure(_) {}
      end

      expect(match).to eq "Matched validate failure"
    end
  end
end
