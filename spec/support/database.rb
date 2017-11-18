RSpec.shared_context "database" do
  include_context "container"

  before do
    Test::NotValidError = Class.new(StandardError)
    Test::DB = []

    Test::Container.register(:database, Test::DB)
  end

  let(:database) { Test::DB }
end
