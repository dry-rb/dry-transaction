RSpec.describe "Using previous steps output with :input option" do
  include_context "database"

  before do
    container.instance_exec do
      register :process,  -> input { { name: input["name"] } }
      register :persist,  -> input do
        tuple = { id: 1, name: input[:name] }
        self[:database] << tuple and tuple
      end
    end
  end

  let(:initial_input) { { "name" => "Jane" } }
  let(:process_output) { { name: "Jane" } }
  let(:persist_output) { { id: 1, name: "Jane" } }

  context "using previous steps output" do
    before do
      container.instance_exec do
        register :log, -> process_output, persist_output { "Processed #{process_output} persisted as #{persist_output}"  }
      end
    end

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
        map :process, with: :process
        map :persist, with: :persist
        map :log, with: :log, input: [:process, :persist]
      end.new
    }

    it "can reference previous steps with the step name" do
      result = transaction.call(initial_input)

      expect(result.value!).to eq("Processed #{process_output} persisted as #{persist_output}")
    end
  end

  context "using previous steps output in different order" do
    before do
      container.instance_exec do
        register :log, -> persist_output, process_output { "Persisted #{persist_output} from processed #{process_output}"  }
      end
    end

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
        map :process, with: :process
        map :persist, with: :persist
        map :log, with: :log, input: [:persist, :process]
      end.new
    }

    it "can specify an order different than the execution order" do
      result = transaction.call(initial_input)

      expect(result.value!).to eq("Persisted #{persist_output} from processed #{process_output}")
    end
  end

  context "using initial input" do
    before do
      container.instance_exec do
        register :log, -> initial_input { "Original #{initial_input} persisted"  }
      end
    end

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
        map :process, with: :process
        tee :persist, with: :persist
        map :log, with: :log, input: [:_initial]
      end.new
    }

    it "can reference initial input with :_initial" do
      result = transaction.call(initial_input)

      expect(result.value!).to eq("Original #{initial_input} persisted")
    end
  end

  context "using no input" do
    before do
      container.instance_exec do
        register(:log, call: false) { "Persisted" }
      end
    end

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
        tee :process, with: :process
        tee :persist, with: :persist
        map :log, with: :log, input: []
      end.new
    }

    it "can reference no input with the empty list" do
      result = transaction.call(initial_input)

      expect(result.value!).to eq('Persisted')
    end
  end

  context "passing additional step arguments" do
    before do
      container.instance_exec do
        register :log, -> process_output, persist_output, time { "Processed #{process_output} persisted as #{persist_output} on #{time}"  }
      end
    end

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
        map :process, with: :process
        map :persist, with: :persist
        map :log, with: :log, input: [:process, :persist]
      end.new
    }

    it "can combine previous outputs along with additional step arguments" do
      result = transaction.with_step_args(log: "2019-01-01").call(initial_input)

      expect(result.value!).to eq("Processed #{process_output} persisted as #{persist_output} on 2019-01-01")
    end
  end
end