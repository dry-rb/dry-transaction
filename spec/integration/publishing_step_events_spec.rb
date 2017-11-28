RSpec.describe "publishing step events" do
  let(:container) {
    Class.new do
      extend Dry::Container::Mixin

      register :process, -> input { {name: input["name"]} }
      register :verify,  -> input { input[:name].to_s != "" ? Dry::Monads.Success(input) : Dry::Monads.Failure("no name") }
      register :persist, -> input { Test::DB << input and true }
    end
  }

  let(:transaction) {
    Class.new do
      include Dry::Transaction(container: Test::Container)

      map :process, with: :process
      step :verify, with: :verify
      tee :persist, with: :persist
    end.new
  }

  let(:subscriber) { spy(:subscriber) }

  before do
    Test::DB = []
    Test::Container = container
  end

  context "subscribing to all step events" do
    before do
      transaction.subscribe(subscriber)
    end

    specify "subscriber receives success events" do
      transaction.call("name" => "Jane")

      expect(subscriber).to have_received(:step_succeeded).with(:process, {name: "Jane"}, {"name" => "Jane"})
      expect(subscriber).to have_received(:step_succeeded).with(:verify, {name: "Jane"}, {name: "Jane"})
      expect(subscriber).to have_received(:step_succeeded).with(:persist, {name: "Jane"}, {name: "Jane"})
    end

    specify "subscriber receives success events for passing steps, a failure event for the failing step, and no subsequent events" do
      transaction.call("name" => "")

      expect(subscriber).to have_received(:step_succeeded).with(:process, {name: ""}, {"name" =>  ""})
      expect(subscriber).to have_received(:step_failed).with(:verify, "no name", {name: ""})
      expect(subscriber).not_to have_received(:step_succeeded).with(:persist)
    end
  end

  context "subscribing to particular step events" do
    before do
      transaction.subscribe(verify: subscriber)
    end

    specify "subscriber receives success event for the specified step" do
      transaction.call("name" => "Jane")

      expect(subscriber).to have_received(:step_succeeded).with(:verify, {name: "Jane"}, {name: "Jane"})
      expect(subscriber).not_to have_received(:step_succeeded).with(:process)
      expect(subscriber).not_to have_received(:step_succeeded).with(:persist)
    end

    specify "subscriber receives failure event for the specified step" do
      transaction.call("name" => "")

      expect(subscriber).to have_received(:step_failed).with(:verify, "no name", {name: ""})
    end
  end

  context "subscribing to step events when passing step arguments" do
    before do
      transaction.subscribe(verify: subscriber)
    end

    let(:container) {
      Class.new do
        extend Dry::Container::Mixin

        register :process, -> input { {name: input["name"]} }
        register :verify,  -> input, name { input[:name].to_s == name ? Dry::Monads.Success(input) : Dry::Monads.Failure("wrong name") }
        register :persist, -> input { Test::DB << input and true }
      end
    }

    specify "subscriber receives success event for the specified step" do
      transaction.with_step_args(verify: ["Jane"]).call("name" => "Jane")

      expect(subscriber).to have_received(:step_succeeded).with(:verify, {:name=>"Jane"}, {:name=>"Jane"}, "Jane")
      expect(subscriber).not_to have_received(:step_succeeded).with(:process)
      expect(subscriber).not_to have_received(:step_succeeded).with(:persist)
    end

    specify "subscriber receives failure event for the specified step" do
      transaction.with_step_args(verify: ["John"]).call("name" => "")

      expect(subscriber).to have_received(:step_failed).with(:verify, "wrong name", {name: ""}, "John")
    end
  end
end
