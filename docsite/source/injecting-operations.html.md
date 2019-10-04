---
title: Injecting operations
layout: gem-single
name: dry-transaction
---

You can inject operation objects into transactions to adjust their behavior at runtime. This could be helpful to substitute operations with test doubles to simulate various conditions in testing.

You can inject operation objects for both ”external” steps (defined using `with:`, pointing to a container registration), as well as “internal” steps (backed by instance methods only).

To inject operation objects, pass them as keyword arguments to the initializer, with their keyword matching their step's name.

Each injected operation must respond to `#call(input, *args)`.

```ruby
class CreateUser
  include Dry::Transaction(container: Container)

  step :prepare
  step :validate, with: "users.validate"
  step :create, with: "users.create"

  private

  def prepare(input)
    Success(input)
  end
end

prepare = -> input { Success(input.merge(name: "#{input[:name]}!!")) }
create  = -> user  { Failure([:could_not_create, user]) }

create_user = CreateUser.new(prepare: prepare, create: create)

create_user.call(name: "Jane", email: "jane@doe.com")
# => Failure([:could_not_create, {:name => "Jane!!", :email => "jane@doe.com"})
```
