require "dry-matcher"
require "dry-monads"


RSpec.describe "Custom matcher" do

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

    MyTransaction.new
  }

  before do
    Test::DB = []
  end

  it "will execute it" do
    transaction.call({"name" => "Jane", "email" => "jane@doe.com"})
    expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
  end

end
