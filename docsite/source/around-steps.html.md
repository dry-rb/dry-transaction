---
title: Around steps
layout: gem-single
name: dry-transaction
---

Regular `step` operations take an input, act on it, and return an output to pass to the next step. They operate in sequence, with control being passed from one operation to the next.

Sometimes, a step operation needs to _wrap_ all of the subsequent steps. A common case for this is handling database transactions. An operation providing a database transaction across steps needs to wrap around all the subsequent operations so it can roll back the transaction in case one of the operations failures.

Use an `around` step to give an operation this behavior. The operation will receive `#call(input, &block)`, where `&block` is the collection of steps it is wrapping. It should call the block to run those steps and handle as appropriate.

An operation to wrap steps in a database transaction would work like this (replace `MyDB` with whatever your database system requires):

```ruby
class MyContainer
  extend Dry::Container

  register "transaction" do |input, &block|
    result = nil

    begin
      MyDB.transaction do
        result = block.(Success(input))
        raise MyDB::Rollback if result.failure?
        result
      end
    rescue MyDB::Rollback
      result
    end
  end
end
```

And can be integrated into a business transaction like this:

```ruby
class MyOperation
  include Dry::Transaction(container: MyContainer)

  around :transaction, with: "transaction"

  # Multiple subsequent steps writing to the database
  step :create_user, with: "users.create"
  step :create_account, with: "accounts.create"
end
```
