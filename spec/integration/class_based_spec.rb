RSpec.describe "Class Base transaction" do

  before do
    module Test
      Container = {
        process:  -> input { {name: input["name"], email: input["email"]} },
        verify:   -> input { Dry::Monads.Right(input) },
        persist:  -> input { Test::DB << input and true },
      }
    end
  end

  let(:transaction) {
    Class.new do
      include Dry::Transaction(container: Test::Container)

      map :process
      step :verify
      tee :persist
    end.new(**options)
  }

  let(:options) { {} }

  before do
    Test::DB = []
  end

  context "Execute class base transaction" do
    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end
  end

  context "Inject explicit operation at initialize" do
    let(:options) {
      {verify: -> input { Dry::Monads.Right(input[:email].upcase) }}
    }

    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include("JANE@DOE.COM")
    end
  end

  context "different step_operations names inside the container" do
    before do
      module Test
        Container = {
          process_step:  -> input { {name: input["name"], email: input["email"]} },
          verify_step:   -> input { Dry::Monads.Right(input) },
          persist_step:  -> input { Test::DB << input and true },
        }
      end
    end

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process, with: :process_step
        step :verify, with: :verify_step
        tee :persist, with: :persist_step
      end.new(**options)
    }

    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end
  end

  context "wrap step operation" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process, with: :process
        step :verify, with: :verify
        tee :persist, with: :persist

        def verify(input)
          new_input = input.merge(yeah: 'Dry-rb')
          super(new_input)
        end
      end.new(options)
    end

    let(:options) { {} }

    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com", yeah: "Dry-rb")
    end
  end

  context "Local step definition" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process, with: :process
        step :verify
        tee :persist, with: :persist

        def verify(input)
          Dry::Monads.Right(input.keys)
        end
      end.new
    end

    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})

      expect(Test::DB).to include([:name, :email])
    end
  end

  context "All steps are local methods" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction()

        map :process, with: :process
        step :verify, with: :verify
        tee :persist, with: :persist

        def process(input)
          input.to_a
        end

        def verify(input)
          Dry::Monads.Right(input)
        end

        def persist(input)
          Test::DB << input and true
        end
      end.new
    end

    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include([["name", "Jane"], ["email", "jane@doe.com"]])
    end
  end
end
