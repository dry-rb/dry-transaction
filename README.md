# Call Sheet

Business transaction DSL. Call Sheet provides a simple way to define a complex business transaction that includes processing by many different objects. It makes error handling a primary concern by using a “[Railway Oriented Programming](http://fsharpforfunandprofit.com/rop/)” approach for capturing and returning errors from any step in the transaction.

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

If your business transaction is sufficiently complex to require independent modelling, then each of its steps likely provides its own meaningful behaviour. Requiring these steps to be independent operations and directly addressable via container means that they can be tested in isolation and easily reused throughout your application. Keeping the business transaction to a high-level, declarative series of steps ensures it’s easy to understand at a glance.

The output of each step and the overall transaction itself is wrapped in [Deterministic](https://github.com/pzol/deterministic) `Result` objects (either `Success(s)` or `Failure(f)`). These allow the steps to be chained together and ensures that processing stops in the case of a failure. Returning a `Result` also ensures that error handling can remain a primary concern while keeping your application logic tidy and readable. Wrapping the step output also means that you can work with a wide variety of operations within your application – they don’t need to return a `Result` already.

## Synopsis

All you need to use Call Sheet is a container of operations that respond to `#call(input)`. Each operation is integrated into the business transaction via one of the following steps:

* `map` – any output is considered successful and returned as `Success(output)`
* `try` – the operation may raise an exception in an error case. This is caught and returned as `Failure(exception)`. The output is otherwise returned as `Success(output)`.
* `tee` – the operation interacts with some external system and has no meaningful output. The original input is passed through and returned as `Success(input)`.
* `raw` – the operation already returns its own `Result` object, and needs no special handling.

```ruby
DB = []

container = {
  process:  -> input { {name: input["name"], email: input["email"]} },
  validate: -> input { input[:email].nil? ? raise "not valid" : input },
  persist:  -> input { DB << input and true }
}

save_user = CallSheet(container: container) do
  map :process
  try :validate
  tee :persist
end

save_user.call("name" => "Jane", "email" => "jane@doe.com")
# => Success({:name=>"Jane", :email=>"jane@doe.com"})

DB
# => [{:name=>"Jane", :email=>"jane@doe.com"}]
```

Each transaction returns a `Success(s)` or `Failure(f)` result. You can handle these different results with Deterministic’s [pattern matching](https://github.com/pzol/deterministic#pattern-matching):

```ruby
save_user.call(name: "Jane", email: "jane@doe.com").match do
  Success(s) do
    puts "Succeeded!"
  end
  Failure(f, where { f == :validate }) do |errors|
    # In a more realistic example, you’d loop through a list of messages in `errors`.
    puts "Couldn’t save this user. Please provide an email address."
  end
  Failure(f) do
    puts "Couldn’t save this user."
  end
end
```

You can use guard expressions like `where { f == :step_name }` in the failure matches to catch failures that arise from particular steps in your transaction.

### Passing additional step arguments

Additional arguments for step operations can be passed at the time of calling your transaction. Provide these arguments as an array, and they’ll be [splatted](https://endofline.wordpress.com/2011/01/21/the-strange-ruby-splat/) into the front of the operation’s arguments. This effectively means that transactions can support operations with any sort of `#call(*args, input)` interface.

```ruby
DB = []

container = {
  process:  -> input { {name: input["name"], email: input["email"]} },
  validate: -> allowed, input { input[:email].include?(allowed) ? raise "not allowed" : input },
  persist:  -> input { DB << input and true }
}

save_user = CallSheet(container: container) do
  map :process
  try :validate
  tee :persist
end

input = {name: "Jane", email: "jane@doe.com"}
save_user.call(input, validate: ["doe.com"])
# => Success({:name=>"Jane", :email=>"jane@doe.com"})

save_user.call(input, validate: ["smith.com"])
# => Failure("not allowed")
```

### Working with a larger container

In practice, your container object won’t be a trivial collection of generically named operations. You can keep your transaction step names simple by using the `with:` option to provide the identifiers for the operations within your container:

```ruby
save_user = CallSheet(container: large_whole_app_container) do
  map :process, with: "attributes.user"
  try :validate, with: "validations.user"
  tee :persist, with: "persistance.commands.update_update"
end
```

### Using inline procs

You can inject some very small pieces of custom behavior into your transaction using inline procs and a `raw` step. This can be helpful if you want to provide a special failure case based on the output of a previous step.

```ruby
update_user = CallSheet(container: container) do
  map :find_user
  raw :check_locked, with: -> input { input.locked? ? Failure("Cannot update locked user") : Success(input) }
  try :validate
  tee :persist
end
```

A `raw` step can also be used if the operation in your container already returns a `Result`, and therefore doesn’t need any special handling.

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

Call Sheet’s error handling is based on Scott Wlaschin’s [Railway Oriented Programming](http://fsharpforfunandprofit.com/rop/), found via Zohaib Rauf’s [Railway Oriented Programming in Elixir](http://zohaib.me/railway-programming-pattern-in-elixir/) blog post. Call Sheet’s behavior as a business transaction library draws heavy inspiration from Piotr Solnica’s [Transflow](http://github.com/solnic/transflow) and Gilbert B Garza’s [Solid Use Case](https://github.com/mindeavor/solid_use_case). Piotr Zolnierek’s [Deterministic](https://github.com/pzol/deterministic) gem makes working with functional programming patterns in Ruby fun and easy. Thank you all!

## License

Copyright © 2015 [Icelab](http://icelab.com.au/). Call Sheet is free software, and may be redistributed under the terms specified in the [license](LICENSE.md).
