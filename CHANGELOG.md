# 0.3.2 / 2015-11-13

* Fixed a bug where additional step arguments were passed in the wrong order for `map` and `raw` steps.

# 0.3.1 / 2015-11-12

* Remove deterministic gem dependency

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
