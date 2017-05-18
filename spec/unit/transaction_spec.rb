RSpec.describe Dry::Transaction do
  before do
    module Test
      Container = {
        upcase: -> input { input.upcase },
        reverse: -> input { input.reverse },
        exclaim_all: -> input { input.split(" ").map { |str| str + "!" }.join(" ") },
      }
    end
  end

  let(:initial_transaction) {
    Class.new do
      include Dry.Transaction(container: Test::Container)

      map :exclaim_all
    end.new
  }

  let(:other_transaction) {
    Class.new do
      include Dry.Transaction(container: Test::Container)

      map :reverse
    end.new
  }

  describe "#prepend" do
    it "prepends the transaction" do
      new_transaction = initial_transaction.prepend(other_transaction)

      expect(new_transaction.call("hello world").right).to eq "dlrow! olleh!"
    end

    it "accepts a transaction defined in a block" do
      new_transaction = initial_transaction.prepend(container: Test::Container) do
        map :reverse
      end

      expect(new_transaction.call("hello world").right).to eq "dlrow! olleh!"
    end

    it "raises an argument error if a transaction is neither passed nor defined" do
      expect { initial_transaction.prepend }.to raise_error(ArgumentError)
    end

    it "leaves the original transaction unmodified" do
      _new_transaction = initial_transaction.prepend(container: Test::Container) do
        map :reverse
      end

      expect(initial_transaction.call("the quick brown fox").right).to eq "the! quick! brown! fox!"
    end
  end

  describe "#append" do
    it "appends the transaction" do
      new_transaction = initial_transaction.append(other_transaction)

      expect(new_transaction.call("hello world").right).to eq "!dlrow !olleh"
    end

    it "accepts a transaction defined in a block" do
      new_transaction = initial_transaction.append(container: Test::Container) do
        map :reverse
      end

      expect(new_transaction.call("hello world").right).to eq "!dlrow !olleh"
    end

    it "leaves the original transaction unmodified" do
      _new_transaction = initial_transaction.append(container: Test::Container) do
        map :reverse
      end

      expect(initial_transaction.call("hello world").right).to eq "hello! world!"
    end
  end

  describe "#remove" do
    let(:initial_transaction) {
      Class.new do
        include Dry.Transaction(container: Test::Container)

        map :upcase
        map :exclaim_all
        map :reverse
      end.new
    }

    it "removes the specified steps" do
      new_transaction = initial_transaction.remove(:exclaim_all, :reverse)
      expect(new_transaction.call("hello world").right).to eq "HELLO WORLD"
    end

    it "leaves the original transaction unmodified" do
      _new_transaction = initial_transaction.remove(:exclaim_all, :reverse)
      expect(initial_transaction.call("hello world").right).to eq "!DLROW !OLLEH"
    end
  end

  describe "#insert" do
    let(:initial_transaction) {
      Class.new do
        include Dry.Transaction(container: Test::Container)

        map :upcase
        map :reverse
      end.new
    }

    let(:other_transaction) {
      Class.new do
        include Dry.Transaction(container: Test::Container)

        map :exclaim_all
      end.new
    }

    it "accepts a transaction passed as an argument" do
      new_transaction = initial_transaction.insert(other_transaction, before: :reverse)

      expect(new_transaction.call("hello world").right).to eq "!DLROW !OLLEH"
    end

    it "accepts a transaction defined in a block" do
      new_transaction = initial_transaction.insert(before: :reverse, container: Test::Container) do
        map :exclaim_all
      end

      expect(new_transaction.call("hello world").right).to eq "!DLROW !OLLEH"
    end

    it "raises an argument error if a transaction is neither passed nor defined" do
      expect { initial_transaction.insert(before: :reverse) }.to raise_error(ArgumentError)
    end

    it "raises an argument error if an invalid step name is provided" do
      expect {
        initial_transaction.insert(before: :non_existent, container: Test::Container) do
          map :exclaim_all
        end
      }.to raise_error(ArgumentError)
    end

    context "before" do
      let!(:new_transaction) {
        initial_transaction.insert(before: :reverse, container: Test::Container) do
          map :exclaim_all
        end
      }

      it "inserts the new steps before the specified one" do
        expect(new_transaction.call("hello world").right).to eq "!DLROW !OLLEH"
      end

      it "leaves the original transaction unmodified" do
        expect(initial_transaction.call("hello world").right).to eq "DLROW OLLEH"
      end
    end

    context "after" do
      let!(:new_transaction) {
        initial_transaction.insert(after: :reverse, container: Test::Container) do
          map :exclaim_all
        end
      }

      it "inserts the new steps after the specified one" do
        expect(new_transaction.call("hello world").right).to eq "DLROW! OLLEH!"
      end

      it "leaves the original transaction unmodified" do
        expect(initial_transaction.call("hello world").right).to eq "DLROW OLLEH"
      end
    end

    context "with code block explicitly passed to step" do
      class WithBlockStepAdapters < ::Dry::Transaction::StepAdapters # :nodoc:
        class WithBlock
          include Dry::Monads::Either::Mixin
          def call(step, input, *args, &cb)
            Right(step.operation.((block_given? ? yield(input) : input), *args))
          end
        end
        register :with_block, WithBlock.new
      end

      let!(:no_block_transaction) {
        Class.new do
          include Dry.Transaction(container: { exclaim_all: -> input { input.split(" ").map { |str| "#{str}!" }.join(" ") } }, step_adapters: WithBlockStepAdapters)

          with_block :exclaim_all
        end.new
      }
      let!(:with_block_transaction) {
        Class.new do
          include Dry.Transaction(container: { exclaim_all: -> input { input.split(" ").map { |str| "#{str}!" }.join(" ") } }, step_adapters: WithBlockStepAdapters)

          with_block :exclaim_all do |input|
            input.gsub(/(?<=\s|\A)/, '¡')
          end
        end.new
      }

      it "inserts normal bangs without block given" do
        expect(no_block_transaction.call("hello world").right).to eq "hello! world!"
      end

      it "inserts spanish bangs with block given" do
        expect(with_block_transaction.call("hello world").right).to eq "¡hello! ¡world!"
      end
    end
  end
end
