RSpec.describe "Standalone use" do
  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []
  end

  it "works" do
    CallSheet {
      map :process,   with: -> input { {name: input["name"], email: input["email"]} }
      raw :verify,    with: -> input { Right(input) }
      try :validate,  with: -> input { input[:email].nil? ? raise(Test::NotValidError, "email required") : input }, catch: Test::NotValidError
      tee :persist,   with: -> input { Test::DB << input and true }
    }.({"name" => "Jane", "email" => "jane@doe.com"})

    expect(Test::DB).to include(name: "Jane", email: "jane@doe.com")
  end
end
