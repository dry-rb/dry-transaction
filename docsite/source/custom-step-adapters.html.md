---
title: Custom step adapters
layout: gem-single
name: dry-transaction
---

You can provide your own step adapters to add custom behaviour to transaction steps. Your step adapters must provide a single `#call(step, input, *args)` method, which should return the step’s result wrapped in a `Result` object.

You can provide your step adapter in a few different ways. You can add it to the built-in `StepAdapters` container (a [`dry-container`](http://dry-rb.org/gems/dry-container)) to make it available to all transactions in your codebase:

```ruby
Dry::Transaction::StepAdapters.register :custom_adapter, MyAdapter.new
```

Or you can make your own container to extend the built-in one, and then pass that to specific transactions:

```ruby
class MyStepAdapters < Dry::Transaction::StepAdapters
  register :custom_adapter, MyAdapter.new
end

class CreateUser
  include Dry::Transaction(container: Container, step_adapters: MyStepAdapters)

  # ...
end
```

An example of a custom step adapter is `enqueue`, which would run its operation in a background queue.

```ruby
QUEUE = []

class MyStepAdapters < Dry::Transaction::StepAdapters
  register :enqueue, -> step, input, *args {
    # In a real app, this would push the operation into a background worker queue
    QUEUE << step.operation.call(input, *args)

    Dry::Monads.Success(input)
  }
end

class CreateUser
  include Dry::Transaction(container: Container, step_adapters: MyStepAdapters)

  step :create
  enqueue :send_welcome_email
end
```
