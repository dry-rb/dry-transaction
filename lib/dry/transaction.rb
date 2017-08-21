require "dry/monads/either"
require "dry/transaction/version"
require "dry/transaction/step_adapters"
require "dry/transaction/builder"

module Dry
  # Business transaction DSL
  module Transaction
    def self.included(klass)
      klass.include(Dry::Transaction())
    end
  end

  # Build a module to make your class a business transaction.
  #
  # A business transaction is a series of callable operation objects that
  # receive input and produce an output.
  #
  # The operations can be instance methods, or objects addressable via `#[]` in
  # a container object that you pass when mixing in this module. The operations
  # must respond to `#call(input, *args)`.
  #
  # Each operation will be called in the order it was specified in your
  # transaction, with its output passed as the input to the next operation.
  # Operations will only be called if the previous step was a success.
  #
  # A step is successful when it returns a [dry-monads](dry-monads) `Right`
  # object wrapping its output value. A step is a failure when it returns a
  # `Left` object.  If your operations already return a `Right` or `Left`, they
  # can be added to your operation as plain `step` steps.
  #
  # Add operation to your transaction with the `step` method.
  #
  # If your operations don't already return `Right` or `Left`, then they can be
  # added to the transaction with the following steps:
  #
  # * `map` --- wrap the output of the operation in a `Right`
  # * `try` --- wrap the output of the operation in a `Right`, unless a certain
  #   exception is raised, which will be caught and returned as a `Left`.
  # * `tee` --- ignore the output of the operation and pass through its original
  #   input as a `Right`.
  #
  # [dry-monads]: https://rubygems.org/gems/dry-monads
  #
  # @example
  #   class MyTransaction
  #     include Dry::Transaction(container: MyContainer)
  #
  #     step :first_step, with: "my_container.operations.first"
  #     step :second_step
  #
  #     def second_step(input)
  #       result = do_something_with(input)
  #       Right(result)
  #     end
  #   end
  #
  #   my_transaction = MyTransaction.new
  #   my_transaction.call(some_input)
  #
  # @param container [#[]] the operations container
  # @param step_adapters [#[]] (Dry::Transaction::StepAdapters) a
  # custom container of step adapters
  #
  # @return [Module] the transaction module
  #
  # @api public
  def self.Transaction(container: nil, step_adapters: Transaction::StepAdapters)
    Transaction::Builder.new(container: container, step_adapters: step_adapters)
  end
end
