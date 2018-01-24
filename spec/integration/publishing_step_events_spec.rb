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

  let(:subscriber) do
    Class.new do
      attr_reader :started, :success, :failed

      def initialize
        @started = []
        @success = []
        @failed = []
      end

      def on_step(event)
        started << event[:step_name]
      end
      def on_step_succeeded(event)
        success << {step_name: event[:step_name], args: event[:args]}
      end
      def on_step_failed(event)
        failed << {step_name: event[:step_name], args: event[:args], value: event[:value]}
      end
    end.new
  end

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

      expected_result = [
        { step_name: :process, args: [ {"name" => "Jane"} ] },
        { step_name: :verify, args: [ { name: "Jane" } ] },
        { step_name: :persist, args: [ { name: "Jane" } ] }
      ]

      expect(subscriber.success).to eq expected_result
    end

    specify "subsriber receives success events for passing steps, a failure event for the failing step, and no subsequent events" do
      transaction.call("name" => "")

      expect(subscriber.success).to eq [ { step_name: :process, args:[ { "name" => "" } ] } ]
      expect(subscriber.failed).to eq [ { step_name: :verify, args: [ { name: ""} ],  value: "no name" } ]
    end
  end

  context "subscribing to particular step events" do
    before do
      transaction.subscribe(verify: subscriber)
    end

    specify "subscriber receives success event for the specified step" do
      transaction.call("name" => "Jane")

      expect(subscriber.success).to eq [ { step_name: :verify, args: [ { name: "Jane" } ] } ]
    end

    specify "subscriber receives failure event for the specified step" do
      transaction.call("name" => "")

      expect(subscriber.failed).to eq [ { step_name: :verify, args: [ { name: ""} ],  value: "no name" } ]
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

      expect(subscriber.success).to eq [ { step_name: :verify, args: [ { name: "Jane" }, "Jane"] } ]
    end

    specify "subscriber receives failure event for the specified step" do
      transaction.with_step_args(verify: ["Jade"]).call("name" => "")

      expect(subscriber.failed).to eq [ { step_name: :verify, args: [ { name: "" }, "Jade"], value: "wrong name"} ]
    end
  end
end
