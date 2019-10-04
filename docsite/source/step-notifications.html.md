---
title: Step notifications
layout: gem-single
name: dry-transaction
---

As well as matching on the final transaction result, you can subscribe to individual steps and trigger specific behaviors based on their success or failure.

You can subscribe to events from specific steps using `#subscribe(step_name: listener)`, or subscribe to all steps via `#subscribe(listener)`.

The transaction will broadcast the following events for each step:

- `step` (with `step_name:` and `args:`, representing the name of the step and an array of arguments passed to the step)
- `step_succeeded` (with `step_name:`, `args:`, and `value:`, which is the return value of the step)
- `step_failed` (with `step_name:`, `args:`, and `value:`)

For example:

```ruby
NOTIFICATIONS = []

class CreateUser
  include Dry::Transaction

  step :validate
  step :create

  private

  def validate(input)
    # ...
  end

  def create(input)
    # ...
  end
end

module UserCreationListener
  extend self

  def on_step(event)
    user = event[:value]
    NOTIFICATIONS << "Started creation of #{user[:email]}"
  end

  def on_step_succeeded(event)
    user = event[:value]
    NOTIFICATIONS << "#{user[:email]} created"
  end

  def on_step_failed(event)
    user = event[:value]
    NOTIFICATIONS << "#{user[:email]} creation failed"
  end
end

create_user = CreateUser.new
create_user.subscribe(create: UserCreationListener)

create_user.call(name: "Jane", email: "jane@doe.com")

NOTIFICATIONS
# => ["Started creation of jane@doe.com", "jane@doe.com created"]
```

This pub/sub mechanism is provided by [dry-events](/gems/dry-events).
