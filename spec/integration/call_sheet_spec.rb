RSpec.describe CallSheet do
  let(:call_sheet) {
    CallSheet(container: container) do
      map :process
      raw :verify
      try :validate, catch: Test::NotValidError
      tee :persist
    end
  }

  let(:container) {
    {
      process:  -> input { {name: input["name"], email: input["email"]} },
      verify:   -> input { Right(input) },
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

    it "calls the operations" do
      call_sheet.call(input)
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end

    it "returns a success" do
      expect(call_sheet.call(input)).to be_a Kleisli::Either::Right
    end

    it "wraps the result of the final operation" do
      expect(call_sheet.call(input).value).to eq(name: "Jane", email: "jane@doe.com")
    end

    it "can be called multiple times to the same effect" do
      call_sheet.call(input)
      call_sheet.call(input)

      expect(Test::DB[0]).to eq(name: "Jane", email: "jane@doe.com")
      expect(Test::DB[1]).to eq(name: "Jane", email: "jane@doe.com")
    end

    it "supports matching on success" do
      results = []

      call_sheet.call(input) do |m|
        m.success do |value|
          results << "success for #{value[:email]}"
        end
      end

      expect(results.first).to eq "success for jane@doe.com"
    end
  end

  context "failed in a try step" do
    let(:input) { {"name" => "Jane"} }

    it "does not run subsequent operations" do
      call_sheet.call(input)
      expect(Test::DB).to be_empty
    end

    it "returns a failure" do
      expect(call_sheet.call(input)).to be_a Kleisli::Either::Left
    end

    it "wraps the result of the failing operation" do
      expect(call_sheet.call(input).value).to be_a Test::NotValidError
    end

    it "supports matching on failure" do
      results = []

      call_sheet.call(input) do |m|
        m.failure do |f|
          results << "Failed: #{f.value}"
        end
      end

      expect(results.first).to eq "Failed: email required"
    end

    it "supports matching on specific step failures" do
      results = []

      call_sheet.call(input) do |m|
        m.failure do |f|
          f.on :validate do |v|
            results << "Validation failure: #{v}"
          end
        end
      end

      expect(results.first).to eq "Validation failure: email required"
    end

    it "supports matching on un-named step failures" do
      results = []

      call_sheet.call(input) do |m|
        m.failure do |f|
          f.on :some_other_step do |v|
            results << "Some other step failure"
          end

          f.otherwise do |v|
            results << "Catch-all failure: #{v}"
          end
        end
      end

      expect(results.first).to eq "Catch-all failure: email required"
    end
  end

  context "failed in a raw step" do
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

    before do
      container[:verify] = -> input { Left("raw failure") }
    end

    it "does not run subsequent operations" do
      call_sheet.call(input)
      expect(Test::DB).to be_empty
    end

    it "returns a failure" do
      expect(call_sheet.call(input)).to be_a Kleisli::Either::Left
    end

    it "returns the failing value from the operation" do
      expect(call_sheet.call(input).value).to eq "raw failure"
    end
  end
end
