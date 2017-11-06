module Dry
  module Transaction
    class InvalidStepDefinition < ArgumentError
      def initialize(key)
        super("Transaction step `#{key}` must respond to `#call`")
      end
    end

    class MissingStepDefinition < ArgumentError
      def initialize(key)
        super("Definition for transaction step `#{key}` is missing")
      end
    end
  end
end
