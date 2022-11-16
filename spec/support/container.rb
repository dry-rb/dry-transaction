# frozen_string_literal: true

RSpec.shared_context "container" do
  before do
    class Test::Container
      extend Dry::Core::Container::Mixin
      extend Dry::Monads[:result]
    end
  end

  let(:container) { Test::Container }
end
