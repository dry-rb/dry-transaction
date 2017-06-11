require "dry/monads/either"
require "dry/transaction/version"
require "dry/transaction/step_adapters"
require "dry/transaction/builder"

module Dry
  # Business transaction DSL
  module Transaction
    def self.included(klass)
      klass.send :include, Dry::Transaction()
    end
  end

  # Define a business transaction.
  #
  # A business transaction is a series of callable operation objects that
  # receive input and produce an output.
  #
  # The operations should be addressable via `#[]` in a container object that
  # you pass when creating the transaction. The operations must respond to
  # `#call(input, *args)`.
  #
  # Each operation will be called in the order it was specified in your
  # transaction, with its output passed as the input to the next operation.
  # Operations will only be called if the previous step was a success.
  #
  # A step is successful when it returns a [dry-monads](dry-monads) `Right` object
  # wrapping its output value. A step is a failure when it returns a `Left`
  # object.  If your operations already return a `Right` or `Left`, they can be
  # added to your operation as plain `step` steps.
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
  #   container = {do_first: some_obj, do_second: some_obj}
  #
  #   my_transaction = Dry.Transaction(container: container) do
  #     step :do_first
  #     step :do_second
  #   end
  #
  #   my_transaction.call(some_input)
  #
  # @param options [Hash] the options hash
  # @option options [#[]] :container the operations container
  # @option options [#[]] :step_adapters (Dry::Transaction::StepAdapters) a custom container of step adapters
  # @option options [Dry::Matcher] :matcher (Dry::Transaction::ResultMatcher) a custom matcher object for result matching block API
  #
  # @return [Dry::Transaction] the transaction object
  #
  # @api public
  def self.Transaction(container: nil, step_adapters: Transaction::StepAdapters)
    Transaction::Builder.new(container: container, step_adapters: step_adapters)
  end
end
