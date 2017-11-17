RSpec.describe "Custom step adapters" do
  let(:transaction) {
    Class.new do
      include Dry::Transaction(container: Test::Container, step_adapters: Test::CustomStepAdapters)

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
        process: -> input { {name: input["name"], email: input["email"]} },
        persist: -> input { Test::DB << input and true },
        deliver: -> input { "Delivered email to #{input[:email]}" },
      }

      class CustomStepAdapters < Dry::Transaction::StepAdapters
        extend Dry::Monads::Result::Mixin

        register :enqueue, -> step, input, *args {
          Test::QUEUE << step.operation.call(input, *args)
          Success(input)
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
