require "dry-matcher"
require "dry-monads"


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
      include Dry::Transaction::Builder.new(container: Test::Container)

      map :process
      step :verify
      tee :persist
    end.new(options)
  }

  before do
    Test::DB = []
  end

  context "Execute class base transaction" do
    let(:options) { {} }

    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
    end
  end

  context "Inject explicit operation at initialize" do
    let(:verify) { -> input { Dry::Monads.Right(input[:email].upcase) }  }
    let(:options) { { verify: verify } }

    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include("JANE@DOE.COM")
    end
  end

  context "wrap step operation" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction::Builder.new(container: Test::Container)

        map :process
        step :verify
        tee :persist

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
        include Dry::Transaction::Builder.new(container: Test::Container)

        map :process
        step :local_method
        tee :persist

        def local_method(input)
          Dry::Monads.Right(input.keys)
        end
      end.new(options)
    end

    let(:options) { {} }
    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include([:name, :email])
    end
  end

  context "All steps are local methods" do
    let(:transaction) do
      Class.new do
        include Dry::Transaction::Builder.new

        map :process
        step :local_method
        tee :persist

        def process(input)
          input.to_a
        end

        def local_method(input)
          Dry::Monads.Right(input)
        end

        def persist(input)
          Test::DB << input and true
        end
      end.new(options)
    end
    let(:options) { {} }
    it "succesfully" do
      transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
      expect(Test::DB).to include([["name", "Jane"], ["email", "jane@doe.com"]])
    end
  end
end
