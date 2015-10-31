# 0.2.0 / Unreleased

* Add `step` alias for the `raw` step adapter. This is a more natural expression for the transaction steps in the cases where they're mostly returning `Result` objects and otherwise need no special handling.
* Remove support for inline procs passed to the `with:` step option. This ensures that every piece of logic in the transaction resides in directly addressable operations in the container, which encourages simplicity in the transaction, and improved testability and reusability across the application as a whole.
* Stop catching all exeptions in `try` steps, and instead require a `catch:` option to be provided with one or more exception classes, e.g. `try :some_step, catch: MyError` or `try :another_step, catch: [MyError, AnotherError]`. This makes the step's failure conditions more explicit and ensures that unexpected exceptions bubble up and halt the program as usual.
* Support subscriptions to step success and failure events.

# 0.1.0 / 2015-10-28

Initial release.
