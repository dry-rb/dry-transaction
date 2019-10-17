---
title: Wrapping operations
layout: gem-single
name: dry-transaction
---

For transactions using operations in a container, you can wrap those operations with instance methods. This is helpful for adjusting the behavior of various operations to better suit the overall flow of your transaction.

To wrap an operation, define an instance method with the same name as a step, and call `super` to invoke the original operation.

```ruby
class CreateUser
  include Dry::Transaction(container: Container)

  step :validate, with: "users.validate"
  step :create, with: "users.create"

  private

  def validate(input)
    adjusted_input = upcase_values(input)
    super(adjusted_input)
  end

  def upcase_values(input)
    input.each_with_object({}) { |(key, value), hash|
      hash[key.to_sym] = value.upcase
    }
  end
end

create_user = CreateUser.new
create_user.call(name: "Jane", email: "jane@doe.com")
# => Success(#<User name="JANE" email="JANE@DOE.COM">)
```
