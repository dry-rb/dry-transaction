# frozen_string_literal: true

RSpec.shared_context "container" do
  before do
    module Test
      class Container
        extend Dry::Core::Container::Mixin
        extend Dry::Monads[:result]
      end
    end
  end

  let(:container) { Test::Container }
end
