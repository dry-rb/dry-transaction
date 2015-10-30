# 0.2.0 / Unreleased

* Add `step` alias for the `raw` step adapter. This is a more natural expression for the transaction steps in the cases where they're mostly returning `Result` objects and otherwise need no special handling.
* Remove support for inline procs passed to the `with:` step option. This ensures that every piece of logic in the transaction resides in directly addressable operations in the container, which encourages simplicity in the transaction, and improved testability and reusability across the application as a whole.

# 0.1.0 / 2015-10-28

Initial release.
