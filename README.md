[gitter]: https://gitter.im/icelab/call_sheet?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[gem]: https://rubygems.org/gems/call_sheet
[code_climate]: https://codeclimate.com/github/icelab/call_sheet
[inch]: http://inch-ci.org/github/icelab/call_sheet

# Call Sheet [![Join the chat at https://gitter.im/icelab/call_sheet](https://badges.gitter.im/Join%20Chat.svg)](gitter)

[![Gem Version](https://img.shields.io/gem/v/call_sheet.svg)][gem]
[![Code Climate](https://img.shields.io/codeclimate/github/icelab/call_sheet.svg)][code_climate]
[![API Documentation Coverage](http://inch-ci.org/github/icelab/call_sheet.svg)][inch]

Call Sheet is a business transaction DSL. It provides a simple way to define a complex business transaction that includes processing by many different objects. It makes error handling a primary concern by using a “[Railway Oriented Programming](http://fsharpforfunandprofit.com/rop/)” approach for capturing and returning errors from any step in the transaction.

Call Sheet is based on the following ideas, drawn mostly from [Transflow](http://github.com/solnic/transflow):

* A business transaction is a series of operations where each can fail and stop processing.
* A business transaction resolves its dependencies using an external container object and it doesn’t know any details about the individual operation objects except their identifiers.
* A business transaction can describe its steps on an abstract level without being coupled to any details about how individual operations work.
* A business transaction doesn’t have any state.
* Each operation shouldn’t accumulate state, instead it should receive an input and return an output without causing any side-effects.
* The only interface of a an operation is `#call(input)`.
* Each operation provides a meaningful functionality and can be reused.
* Errors in any operation can be easily caught and handled as part of the normal application flow.

## Why?

Requiring a business transaction's steps to exist as independent operations directly addressable via a container means that they can be tested in isolation and easily reused throughout your application. Following from this, keeping the business transaction to a series of high-level, declarative steps ensures that it's easy to understand at a glance.

The output of each step is wrapped in a [Kleisli](https://github.com/txus/kleisli) `Either` object (`Right` for success or `Left` for failure). This allows the steps to be chained together and ensures that processing stops in the case of a failure. Returning an `Either` from the overall transaction also allows for error handling to remain a primary concern without it getting in the way of tidy, straightforward operation logic. Wrapping the step output also means that you can work with a wide variety of operations within your application – they don’t need to return an `Either` already.

## Synopsis

All you need to use Call Sheet is a container of operations that respond to `#call(input)`. The operations will be resolved from the container via `#[]`. The examples below use a plain Hash for simplicity, but for a larger app you may like to consider something like [dry-container](https://github.com/dryrb/dry-container).

Each operation is integrated into your business transaction through one of the following step adapters:

* `map` – any output is considered successful and returned as `Right(output)`
* `try` – the operation may raise an exception in an error case. This is caught and returned as `Left(exception)`. The output is otherwise returned as `Right(output)`.
* `tee` – the operation interacts with some external system and has no meaningful output. The original input is passed through and returned as `Right(input)`.
* `raw` or `step` – the operation already returns its own `Either` object, and needs no special handling.

```ruby
DB = []

container = {
  process:  -> input { {name: input["name"], email: input["email"]} },
  validate: -> input { input[:email].nil? ? raise(ValidationFailure, "not valid") : input },
  persist:  -> input { DB << input and true }
}

save_user = CallSheet(container: container) do
  map :process
  try :validate, catch: ValidationFailure
  tee :persist
end

save_user.call("name" => "Jane", "email" => "jane@doe.com")
# => Right({:name=>"Jane", :email=>"jane@doe.com"})

DB
# => [{:name=>"Jane", :email=>"jane@doe.com"}]
```

Each transaction returns a result value wrapped in a `Left` or `Right` object. You can handle these different results (including errors arising from particular steps) with a match block:

```ruby
save_user.call(name: "Jane", email: "jane@doe.com") do |m|
  m.success do
    puts "Succeeded!"
  end

  m.failure do |f|
    f.on :validate do |errors|
      # In a more realistic example, you’d loop through a list of messages in `errors`.
      puts "Couldn’t save this user. Please provide an email address."
    end

    f.otherwise do |error|
      puts "Couldn’t save this user."
    end
  end
end
```

### Passing additional step arguments

Additional arguments for step operations can be passed at the time of calling your transaction. Provide these arguments as an array, and they’ll be [splatted](https://endofline.wordpress.com/2011/01/21/the-strange-ruby-splat/) into the front of the operation’s arguments. This means that transactions can effectively support operations with any sort of `#call(*args, input)` interface.

```ruby
DB = []

container = {
  process:  -> input { {name: input["name"], email: input["email"]} },
  validate: -> allowed, input { input[:email].include?(allowed) ? raise(ValidationFailure, "not allowed") : input },
  persist:  -> input { DB << input and true }
}

save_user = CallSheet(container: container) do
  map :process
  try :validate, catch: ValidationFailure
  tee :persist
end

input = {"name" => "Jane", "email" => "jane@doe.com"}
save_user.call(input, validate: ["doe.com"])
# => Right({:name=>"Jane", :email=>"jane@doe.com"})

save_user.call(input, validate: ["smith.com"])
# => Left("not allowed")
```

### Subscribing to step notifications

As well as pattern matching on the final transaction result, you can subscribe to individual steps and trigger specific behaviour based on their success or failure:

```ruby
NOTIFICATIONS = []

module UserPersistListener
  extend self

  def persist_success(user)
    NOTIFICATIONS << "#{user[:email]} persisted"
  end

  def persist_failure(user)
    NOTIFICATIONS << "#{user[:email]} failed to persist"
  end
end


input = {"name" => "Jane", "email" => "jane@doe.com"}

save_user.subscribe(persist: UserPersistListener)
save_user.call(input, validate: ["doe.com"])

NOTIFICATIONS
# => ["jane@doe.com persisted"]
```

This pub/sub mechanism is provided by the [Wisper](https://github.com/krisleech/wisper) gem. You can subscribe to specific steps using the `#subscribe(step_name: listener)` API, or subscribe to all steps via `#subscribe(listener)`.

### Working with a larger container

In practice, your container won’t be a trivial collection of generically named operations. You can keep your transaction step names simple by using the `with:` option to provide the identifiers for the operations within your container:

```ruby
save_user = CallSheet(container: large_whole_app_container) do
  map :process, with: "attributes.user"
  try :validate, with: "validations.user", catch: ValidationFailure
  tee :persist, with: "persistance.commands.update_user"
end
```

A `raw` step (also aliased as `step`) can be used if the operation in your container already returns an `Either` and therefore doesn’t need any special handling.

## Installation

Add this line to your application’s `Gemfile`:

```ruby
gem "call_sheet"
```

Run `bundle` to install the gem.

## Contributing

Bug reports and pull requests are welcome on [GitHub](http://github.com/icelab/call_sheet).

## Credits

Call Sheet is developed and maintained by [Icelab](http://icelab.com.au/).

Call Sheet’s error handling is based on Scott Wlaschin’s [Railway Oriented Programming](http://fsharpforfunandprofit.com/rop/), found via Zohaib Rauf’s [Railway Oriented Programming in Elixir](http://zohaib.me/railway-programming-pattern-in-elixir/) blog post. Call Sheet’s behavior as a business transaction library draws heavy inspiration from Piotr Solnica’s [Transflow](http://github.com/solnic/transflow) and Gilbert B Garza’s [Solid Use Case](https://github.com/mindeavor/solid_use_case). Josep M. Bach’s [Kleisli](https://github.com/txus/kleisli) gem makes functional programming patterns in Ruby accessible and fun. Thank you all!

## License

Copyright © 2015 [Icelab](http://icelab.com.au/). Call Sheet is free software, and may be redistributed under the terms specified in the [license](LICENSE.md).
