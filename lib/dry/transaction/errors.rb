module Dry
  module Transaction
    class InvalidStepDefinition < ArgumentError
      def initialize(key)
        super("Transaction step `#{key}` must be defined and respond to `#call`")
      end
    end
  end
end
