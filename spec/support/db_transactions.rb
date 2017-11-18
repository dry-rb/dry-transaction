RSpec.shared_context "db transactions" do
  include_context "database"

  before do
    Test::Rollback = Class.new(StandardError)

    class << Test::DB
      attr_accessor :in_transaction, :rolled_back, :committed
      alias_method :in_transaction?, :in_transaction
      alias_method :rolled_back?, :rolled_back
      alias_method :committed?, :committed

      def transaction
        self.in_transaction = true
        self.rolled_back = false
        self.committed = false

        yield.tap do
          self.committed = true
        end
      rescue => error
        self.rolled_back = true
        clear

        raise error
      ensure
        self.in_transaction = false
      end
    end

    container.register(:transaction) do |input, &block|
      result = nil

      begin
        Test::DB.transaction do
          result = block.(Success(input))
          raise Test::Rollback if result.failure?
          result
        end
      rescue Test::Rollback
        result
      end
    end
  end
end
