require "deterministic"
require "call_sheet/version"
require "call_sheet/dsl"

# Define a business transaction.
#
# A business transaction is a series of callable operation objects that
# receive input and produce an output.
#
# The operations should be addressable via `#[]` in a container object that
# you pass when creating the transaction. The operations must respond to
# `#call(*args, input)`.
#
# Each operation will be called in the order it was specified in your
# transaction, with its output is passed as the intput to the next operation.
# Operations will only be called if the previous step was a success.
#
# A step is successful when it returns a `Success` object (from the
# [Deterministic](deterministic) gem) wrapping its output value. A step is a
# failure when it returns a `Failure` object.  If your operations already
# return a `Success` or `Failure`, they can be added to your operation as
# plain `step` or `raw` steps.
#
# If your operations don't already return `Success` or `Failure`, then they
# can be added to the transaction with the following steps:
#
# * `map` --- wrap the output of the operation in a `Success`
# * `try` --- wrap the output of the operation in a `Success`, unless a certain
#   exception is raised, which will be caught and returned as a `Failure`.
# * `tee` --- ignore the output of the operation and pass through its original
#   input as a `Sucess`.
#
# [deterministic]: https://github.com/pzol/deterministic
#
# @example
#   container = {do_first: some_obj, do_second: some_obj}
#
#   my_transaction = CallSheet(container: container) do
#     step :do_first
#     step :do_second
#   end
#
#   my_transaction.call(some_input)
#
# @param [Hash] options the options hash
# @option options [#[]] :container the operations container
#
# @return [CallSheet::Transaction] the transaction object
#
# @api public
def CallSheet(options = {}, &block)
  CallSheet::DSL.new(options, &block).call
end
