---
title: Basic usage
layout: gem-single
name: dry-transaction
---

### Defining a transaction with local operations

You can define a standalone transaction based around a single class and its own instance methods. Each instance method must accept an input argument and return an output wrapped in a `Success` or `Failure`:

```ruby
require "dry/transaction"

class CreateUser
  include Dry::Transaction

  step :validate
  step :create

  private

  def validate(input)
    # returns Success(valid_data) or Failure(validation)
  end

  def create(input)
    # returns Success(user)
  end
end
```

### Defining a transaction with an operations container

You can also define a transaction that relies upon operation objects in a container. Each operation must respond to `#call(input)`.

The container will be checked for the operations using `#key?`, and the operations will be resolved from the container via `#[]`. For this example, we’ll use [dry-container](/gems/dry-container):

```ruby
require "dry/container"
require "dry/transaction"
require "dry/transaction/operation"

module Users
  class Validate
    include Dry::Transaction::Operation

    def call(input)
      # returns Success(valid_data) or Failure(validation)
    end
  end

  class Create
    include Dry::Transaction::Operation

    def call(input)
      # returns Success(user)
    end
  end
end

class Container
  extend Dry::Container::Mixin

  namespace "users" do
    register "validate" do
      Users::Validate.new
    end

    register "create" do
      Users::Create.new
    end
  end
end
```

n.b. this is a small, contrived container setup. In a real app, you should consider using [dry-system](/gems/dry-system) to make it easier to populate a container with your own objects.

Once you have a container, you can pass it to your transaction mixin and refer to the registered operations.

```ruby
class CreateUser
  include Dry::Transaction(container: Container)

  step :validate, with: "users.validate"
  step :create, with: "users.create"
end
```

### Creating a reusable transaction module

You can create a reusable transaction module if you want to share configuration (i.e. container or step adapters) across multiple transaction classes.

```ruby
module MyApp
  Transaction = Dry::Transaction(container: Container)
end

class CreateUser
  include MyApp::Transaction

  # Operations will be resolved from the `Container` specified above
  step :validate, with: "users.validate"
  step :create, with: "users.create"
end
```

### Calling a transaction

Calling a transaction will run its operations in their specified order, with the output of each operation becoming the input for the next.

```ruby
create_user = CreateUser.new
create_user.call(name: "Jane", email: "jane@doe.com")
# => Success(#<User name="Jane", email="jane@doe.com">)
```

Each transaction returns a result value wrapped in a `Success` or `Failure` object, based on the output of its final step. You can handle these results (including errors arising from particular steps) with a match block:

```ruby
create_user.call(name: "Jane", email: "jane@doe.com") do |m|
  m.success do |user|
    puts "Created user for #{user.name}!"
  end

  m.failure :validate do |validation|
    # Runs only when the transaction fails on the :validate step
    puts "Please provide a valid user."
  end

  m.failure do |error|
    # Runs for any other failure
    puts "Couldn’t create this user."
  end
end
```

The match cases are executed in order. The first match wins and halts subsequent matching. The result from the match also becomes the method call’s return value.

### Passing additional step arguments

You can pass additional arguments to step operations using `#with_step_args`. Provide the operations as keys, and the arguments as an array. The arguments array will be [splatted](https://endofline.wordpress.com/2011/01/21/the-strange-ruby-splat/) into the end of the operation’s arguments.

By using `#with_step_args` to pass additional step arguments, you can include operations in a transaction with any sort of `#call(input, *args)` interface, including keyword arguments.

```ruby
class CreateUser
  include Dry::Transaction(container: Container)

  step :validate
  step :create
  step :notify

  private

  def validate(input)
    # ...
  end

  def create(input, account_id:)
    # ...
  end

  def notify(user, recipient)
    # ...
  end
end

create_user = CreateUser.new

create_user
  .with_step_args(
    create: [account_id: 123],
    notify: ["foo@bar.com"],
  )
  .call(name: "Jane", email: "jane@doe.com")
```
