# frozen_string_literal: true

RSpec.describe Dry::Transaction::ResultMatcher do
  include Dry::Monads[:result]

  describe "when failure" do
    it "can match using multiple step names" do
      expected = Object.new
      actual = nil

      failure = Failure(Dry::Transaction::StepFailure.new(Struct.new(:name).new(:step), expected))
      Dry::Transaction::ResultMatcher.(failure) do |on|
        on.success { raise }
        on.failure(:step, :other_step) { |value| actual = value }
      end

      expect(actual).to be expected
    end
  end
end
