RSpec.shared_context "container" do
  before do
    class Test::Container
      extend Dry::Container::Mixin
      extend Dry::Monads::Result::Mixin
    end
  end

  let(:container) { Test::Container }
end
