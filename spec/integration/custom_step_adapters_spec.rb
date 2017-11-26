RSpec.describe "Custom step adapters" do
  let(:transaction) {
    Class.new do
      include Dry::Transaction(container: Test::Container, step_adapters: Test::CustomStepAdapters)

      check :jane?, with: :jane?
      map :process, with: :process
      tee :persist, with: :persist
      enqueue :deliver, with: :deliver
    end.new
  }

  before do
    Test::DB = []
    Test::QUEUE = []

    module Test
      Container = {
        jane?:   -> input { input["name"] == "Jane" },
        process: -> input { {name: input["name"], email: input["email"]} },
        persist: -> input { Test::DB << input and true },
        deliver: -> input { "Delivered email to #{input[:email]}" },
      }

      class CustomStepAdapters < Dry::Transaction::StepAdapters
        extend Dry::Monads::Result::Mixin

        register :enqueue, -> operation, _options, args {
          Test::QUEUE << operation.(*args)
          Success(args[0])
        }
      end
    end
  end

  it "supports custom step adapters" do
    input = {"name" => "Jane", "email" => "jane@doe.com"}
    transaction.call(input)
    expect(Test::QUEUE).to include("Delivered email to jane@doe.com")
  end
end
