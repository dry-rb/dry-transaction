RSpec.describe "publishing step events" do
  let(:call_sheet) {
    CallSheet(container: container) do
      map :process
      raw :verify
      tee :persist
    end
  }

  let(:container) {
    {
      process:  -> input { {name: input["name"]} },
      verify:   -> input { input[:name].to_s != "" ? Right(input) : Left("no name") },
      persist:  -> input { Test::DB << input and true }
    }
  }

  let(:subscriber) { spy(:subscriber) }

  before do
    Test::DB = []
  end

  context "subscribing to all step events" do
    before do
      call_sheet.subscribe(subscriber)
    end

    specify "subscriber receives success events" do
      call_sheet.call("name" => "Jane")

      expect(subscriber).to have_received(:process_success).with(name: "Jane")
      expect(subscriber).to have_received(:verify_success).with(name: "Jane")
      expect(subscriber).to have_received(:persist_success).with(name: "Jane")
    end

    specify "subsriber receives success events for passing steps, a failure event for the failing step, and no subsequent events" do
      call_sheet.call("name" => "")

      expect(subscriber).to have_received(:process_success).with(name: "")
      expect(subscriber).to have_received(:verify_failure).with({name: ""}, "no name")
      expect(subscriber).not_to have_received(:persist_success)
    end
  end

  context "subscribing to particular step events" do
    before do
      call_sheet.subscribe(verify: subscriber)
    end

    specify "subscriber receives success event for the specified step" do
      call_sheet.call("name" => "Jane")

      expect(subscriber).to have_received(:verify_success).with(name: "Jane")
      expect(subscriber).not_to have_received(:process_success)
      expect(subscriber).not_to have_received(:persist_success)
    end

    specify "subscriber receives failure event for the specified step" do
      call_sheet.call("name" => "")

      expect(subscriber).to have_received(:verify_failure).with({name: ""}, "no name")
    end
  end
end
