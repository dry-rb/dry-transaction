---
title: Step adapters
layout: gem-single
name: dry-transaction
---

`step` adds operations to your transaction that already return a `Result` object. If you have to work with other types of operations, you can use an alternative _step adapter_. Step adapters can wrap the output of your operations to make them easier to integrate into a transaction. The following adapters are available:

- `map` – any output is considered successful and returned as `Success(output)`
- `check` - the operation returns a boolean. True values return the original input as `Success(input)`. Any other values return the original input as `Failure(input)`.
- `try` – the operation may raise an exception in an error case. This is caught and returned as `Failure(exception)`. The output is otherwise returned as `Success(output)`.
- `tee` – the operation interacts with some external system and has no meaningful output. The original input is passed through and returned as `Success(input)`.

These step adapters in use look like this:

```ruby
class CreateUser
  include Dry::Transaction(container: Container)

  map :process
  try :validate, catch: ValidationError
  map :create
  tee :notify
end
```
