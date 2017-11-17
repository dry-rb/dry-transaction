RSpec.describe "Transactions" do
  let(:dependencies) { {} }

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
    class Test::Container
      extend Dry::Container::Mixin
      register :process,  -> input { {name: input["name"], email: input["email"]} }
      register :verify,   -> input { Dry::Monads::Success(input) }
      register :validate, -> input { input[:email].nil? ? raise(Test::NotValidError, "email required") : input }
      register :persist,  -> input { Test::DB << input and true }
    end
  end

  context "successful" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
          map :process
          step :verify
          try :validate, catch: Test::NotValidError
          tee :persist
      end.new(**dependencies)
    }
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

    it "calls the operations" do
      transaction.call(input)
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end

    it "returns a success" do
      expect(transaction.call(input)).to be_a Dry::Monads::Result::Success
    end

    it "wraps the result of the final operation" do
      expect(transaction.call(input).value!).to eq(name: "Jane", email: "jane@doe.com")
    end

    it "can be called multiple times to the same effect" do
      transaction.call(input)
      transaction.call(input)

      expect(Test::DB[0]).to eq(name: "Jane", email: "jane@doe.com")
      expect(Test::DB[1]).to eq(name: "Jane", email: "jane@doe.com")
    end

    it "supports matching on success" do
      results = []

      transaction.call(input) do |m|
        m.success do |value|
          results << "success for #{value[:email]}"
        end

        m.failure { }
      end

      expect(results.first).to eq "success for jane@doe.com"
    end
  end

  context "different step names" do
    before do
      class Test::ContainerNames
        extend Dry::Container::Mixin
        register :process_step,  -> input { {name: input["name"], email: input["email"]} }
        register :verify_step,   -> input { Dry::Monads::Success(input) }
        register :persist_step,  -> input { Test::DB << input and true }
      end
    end

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::ContainerNames)

        map :process, with: :process_step
        step :verify, with: :verify_step
        tee :persist, with: :persist_step
      end.new(**dependencies)
    }

    it "supports steps using differently named container operations" do
      transaction.call("name" => "Jane", "email" => "jane@doe.com")
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end
  end

  describe "operation injection" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
          map :process
          step :verify_step, with: :verify
          tee :persist
      end.new(**dependencies)
    }

    let(:dependencies) {
      {verify_step: -> input { Success(input.merge(foo: :bar)) }}
    }

    it "calls injected operations" do
      transaction.call("name" => "Jane", "email" => "jane@doe.com")

      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com", foo: :bar)
    end
  end

  context "wrapping operations with local methods" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process, with: :process
        step :verify, with: :verify
        tee :persist, with: :persist

        def verify(input)
          new_input = input.merge(greeting: "hello!")
          super(new_input)
        end
      end.new(**dependencies)
    end

    let(:dependencies) { {} }

    it "allows local methods to run operations via super" do
      transaction.call("name" => "Jane", "email" => "jane@doe.com")

      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com", greeting: "hello!")
    end
  end

  context "wrapping operations with private local methods" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process, with: :process
        step :verify, with: :verify
        tee :persist, with: :persist

        private

        def verify(input)
          new_input = input.merge(greeting: "hello!")
          super(new_input)
        end
      end.new(**dependencies)
    end

    let(:dependencies) { {} }

    it "allows local methods to run operations via super" do
      transaction.call("name" => "Jane", "email" => "jane@doe.com")

      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com", greeting: "hello!")
    end
  end

  context "local step definition" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process, with: :process
        step :verify
        tee :persist, with: :persist

        def verify(input)
          Success(input.keys)
        end
      end.new
    end

    it "execute step only defined as local method" do
      transaction.call("name" => "Jane", "email" => "jane@doe.com")

      expect(Test::DB).to include([:name, :email])
    end
  end

  context "local step definition not in container" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction(container: Test::Container)

        map :process, with: :process
        step :verify_only_local
        tee :persist, with: :persist

        def verify_only_local(input)
          Success(input.keys)
        end
      end.new
    end

    it "execute step only defined as local method" do
      transaction.call("name" => "Jane", "email" => "jane@doe.com")

      expect(Test::DB).to include([:name, :email])
    end
  end


  context "all steps are local methods" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction

        map :process
        step :verify
        tee :persist

        def process(input)
          input.to_a
        end

        def verify(input)
          Success(input)
        end

        def persist(input)
          Test::DB << input and true
        end
      end.new
    end

    it "executes succesfully" do
      transaction.call("name" => "Jane", "email" => "jane@doe.com")
      expect(Test::DB).to include([["name", "Jane"], ["email", "jane@doe.com"]])
    end
  end

  context "failed in a try step" do
    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::Container)
        map :process
        step :verify
        try :validate, catch: Test::NotValidError
        tee :persist
      end.new(**dependencies)
    }
    let(:input) { {"name" => "Jane"} }

    it "does not run subsequent operations" do
      transaction.call(input)
      expect(Test::DB).to be_empty
    end

    it "returns a failure" do
      expect(transaction.call(input)).to be_a Dry::Monads::Result::Failure
    end

    it "wraps the result of the failing operation" do
      expect(transaction.call(input).left).to be_a Test::NotValidError
    end

    it "supports matching on failure" do
      results = []

      transaction.call(input) do |m|
        m.success { }

        m.failure do |value|
          results << "Failed: #{value}"
        end
      end

      expect(results.first).to eq "Failed: email required"
    end

    it "supports matching on specific step failures" do
      results = []

      transaction.call(input) do |m|
        m.success { }

        m.failure :validate do |value|
          results << "Validation failure: #{value}"
        end
      end

      expect(results.first).to eq "Validation failure: email required"
    end

    it "supports matching on un-named step failures" do
      results = []

      transaction.call(input) do |m|
        m.success { }

        m.failure :some_other_step do |value|
          results << "Some other step failure"
        end

        m.failure do |value|
          results << "Catch-all failure: #{value}"
        end
      end

      expect(results.first).to eq "Catch-all failure: email required"
    end
  end

  context "failed in a raw step" do
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

    before do
      class Test::ContainerRaw
        extend Dry::Container::Mixin
        register :process_step,  -> input { {name: input["name"], email: input["email"]} }
        register :verify_step,   -> input { Dry::Monads::Failure("raw failure") }
        register :persist_step,  -> input { Test::DB << input and true }
      end
    end

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::ContainerRaw)

        map :process, with: :process_step
        step :verify, with: :verify_step
        tee :persist, with: :persist_step
      end.new(**dependencies)
    }

    it "does not run subsequent operations" do
      transaction.call(input)
      expect(Test::DB).to be_empty
    end

    it "returns a failure" do
      expect(transaction.call(input)).to be_a_failure
    end

    it "returns the failing value from the operation" do
      expect(transaction.call(input).left).to eq "raw failure"
    end

    it "returns an object that quacks like expected" do
      result = transaction.call(input).left

      expect(Array(result)).to eq(['raw failure'])
    end

    it "does not allow to call private methods on the result accidently" do
      result = transaction.call(input).left

      expect { result.print('') }.to raise_error(NoMethodError)
    end
  end

  context "non-confirming raw step result" do
    let(:input) { {"name" => "Jane", "email" => "jane@doe.com"} }

    let(:transaction) {
      Class.new do
        include Dry::Transaction(container: Test::ContainerRaw)
        map :process
        step :verify
        tee :persist
      end.new(**dependencies)
    }

    before do
      class Test::ContainerRaw
        extend Dry::Container::Mixin
        register :process,  -> input { {name: input["name"], email: input["email"]} }
        register :verify,   -> input { "failure" }
        register :persist,  -> input { Test::DB << input and true }
      end
    end

    it "raises an exception" do
      expect { transaction.call(input) }.to raise_error(ArgumentError)
    end
  end

  context "keyword arguments" do
    let(:input) { { name: 'jane', age: 20 } }

    let(:upcaser) do
      Class.new {
        def call(name: 'John', **rest)
          Dry::Monads::Success(name: name[0].upcase + name[1..-1], **rest)
        end
      }.new
    end

    let(:transaction) do
      Class.new {
        include Dry::Transaction

        step :camelize

      }.new(camelize: upcaser)
    end

    it "calls the operations" do
      expect(transaction.(input).value).to eql(name: 'Jane', age: 20)
    end
  end

  context "invalid steps" do
    context "non-callable step" do
      context "with container" do
        let(:input) { {} }

        let(:transaction) {
          Class.new do
            include Dry::Transaction(container: Test::ContainerRaw)
            map :not_a_proc
          end.new
        }

        before do
          class Test::ContainerRaw
            extend Dry::Container::Mixin

            register :not_a_proc, "definitely not a proc"
          end
        end

        it "raises an exception" do
          expect { transaction.call(input) }.to raise_error(Dry::Transaction::InvalidStepError)
        end
      end
    end

    context "missing steps" do
      context "no container" do
        let(:input) { {} }

        let(:transaction) {
          Class.new do
            include Dry::Transaction
            map :noop
            map :i_am_missing

            def noop
              Success(input)
            end
          end.new
        }

        it "raises an exception" do
          expect { transaction.call(input) }.to raise_error(Dry::Transaction::MissingStepError)
        end
      end

      context "with container" do
        let(:input) { {} }

        let(:transaction) {
          Class.new do
            include Dry::Transaction(container: Test::ContainerRaw)
            map :noop
            map :i_am_missing

          end.new
        }

        before do
          class Test::ContainerRaw
            extend Dry::Container::Mixin

            register :noop, -> input { Success(input) }
          end
        end

        it "raises an exception" do
          expect { transaction.call(input) }.to raise_error(Dry::Transaction::MissingStepError)
        end
      end
    end
  end
end
