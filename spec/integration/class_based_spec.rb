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
    class MyTransaction
      include Dry.Transaction(Test::Container)

      map :process
      step :verify
      tee :persist
    end

    MyTransaction.new(options)
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

end
