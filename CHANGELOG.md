# 0.9.0 / Unreleased

## Added

- Support for passing blocks to step adapters (am-kantox)

    ```ruby
    Dry.Transaction(container: MyContainer) do
      my_custom_step :some_step do
        # this code is captured as a block and passed to the step adapter
      end
    end
    ```

# 0.8.0 / 2016-07-06

## Changed

- Match block API is now provided by `dry-matcher` gem (timriley)
- Matching behaviour is clearer: match cases are run in order, the first match case “wins” and is executed, and all subsequent cases are ignored. This ensures a single, deterministic return value from the match block - the output of the single “winning” match case. (timriley)

## Added

- Provide your own matcher object via a `matcher:` option passed to `Dry.Transaction` (timriley)

# 0.7.0 / 2016-06-06

## Added

* `try` steps support a `:raise` option, so a caught exception can be re-raised as a different (more domain-specific) exception (mrbongiolo)

## Changed

* Use dry-monads (e.g. `Dry::Monads::Either::Right`) instead of kleisli (`Kleisli::Either::Right`) (flash-gordon)

## Fixed

* Add `#respond_to_missing?` to `StepFailure` wrapper class so it can more faithfully represent the failure object it wraps (flash-gordon)
* Stop the DSL processing from conflicting with ActiveSupport's `Object#try` monkey-patch (joevandyk)

[Compare v0.6.0...v0.7.0](https://github.com/dry-rb/dry-transaction/compare/v0.6.0...v0.7.0)

# 0.6.0 / 2016-04-06

## Added

* Allow custom step adapters to be supplied via a container of adapters being passed as a `step_adapters:` option to `Dry.Transaction` (timriley)
* Raise a meaningful error if a `step` step returns a non-`Either` object (davidpelaez)

## Internal

* Change the step adapter API so more step-related information remains available at the time of the step being called (timriley)

[Compare v0.5.0...v0.6.0](https://github.com/dry-rb/dry-transaction/compare/v0.5.0...v0.6.0)

# 0.5.0 / 2016-03-16

* Renamed gem to `dry-transaction`
* Transactions are now defined via `Dry.Transaction(options)`

# 0.4.0 / 2015-12-26

* Added `Transaction#append`, `#prepend`, `#insert` and `#remove` for modifying existing transactions and returning new copies.
* Removed `raw` step adapter name - `step` should be used instead.

# 0.3.2 / 2015-11-13

* Fixed a bug where additional step arguments were passed in the wrong order for `map` and `raw` steps.

# 0.3.1 / 2015-11-12

* Removed deterministic gem dependency

# 0.3.0 / 2015-11-11

* Use Kleisli’s `Either` monad for wrapping the result value instead of Determinstic’s `Result`.
* Add built-in, expressive result matching via a block passed to `#call`.
* Fixed a bug in which the input object could be modified over multiple calls.

# 0.2.0 / 2015-11-02

* Added support for subscriptions to step success and failure events.
* Stopped catching all exeptions in `try` steps. Instead, require a `catch:` option to be provided with one or more exception classes, e.g. `try :some_step, catch: MyError` or `try :another_step, catch: [MyError, AnotherError]`. This makes the step's failure conditions explicit and ensures that unexpected exceptions bubble up and halt the program as usual.
* Added a `step` alias for the `raw` step adapter. This is a more natural expression for transactions in which most of the steps already return `Result` objects and otherwise need no special handling.
* Removed support for inline procs passed to the `with:` step option. This ensures that every piece of logic in the transaction resides in directly addressable operations in the container, which encourages simplicity in the transaction, and improved testability and reusability across the application as a whole.

# 0.1.0 / 2015-10-28

Initial release.
