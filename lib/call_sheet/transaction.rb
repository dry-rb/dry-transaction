require "call_sheet/result_matcher"

module CallSheet
  class Transaction
    # @api private
    attr_reader :steps
    private :steps

    # @api private
    def initialize(steps)
      @steps = steps
    end

    # Run the transaction.
    #
    # Each operation will be called in the order it was specified, with its
    # output passed as input to the next operation. Operations will only be
    # called if the previous step was a success.
    #
    # If any of the operations require extra arguments beyond the main input
    # e.g. with a signature like `#call(something_else, input)`, then you must
    # pass the extra arguments as arrays for each step in the options hash.
    #
    # @example Running a transaction
    #   my_transaction.call(some_input)
    #
    # @example Running a transaction with extra step arguments
    #   my_transaction.call(some_input, step_name: [extra_argument])
    #
    # The return value will be the output from the last operation, wrapped in
    # a [Kleisli](kleisli) `Either` object, a `Right` for a successful
    # transaction or a `Left` for a failed transaction.
    #
    # [kleisli]: https://rubygems.org/gems/kleisli
    #
    # @param input
    # @param options [Hash] extra step arguments
    #
    # @return [Right, Left] output from the final step
    #
    # @api public
    def call(input, options = {}, &block)
      assert_valid_options(options)
      assert_options_satisfy_step_arity(options)

      steps = steps_with_options_applied(options)
      result = steps.inject(Right(input), :>>)

      if block
        block.call(ResultMatcher.new(result))
      else
        result
      end
    end
    alias_method :[], :call

    # Subscribe to notifications from steps.
    #
    # When each step completes, it will send a `[step_name]_success` or
    # `[step_name]_failure` message to any subscribers.
    #
    # For example, if you had a step called `persist`, then it would send
    # either `persist_success` or `persist_failure` messages to subscribers
    # after the operation completes.
    #
    # Pass a single object to subscribe to notifications from all steps, or
    # pass a hash with step names as keys to subscribe to notifications from
    # specific steps.
    #
    # @example Subscribing to notifications from all steps
    #   my_transaction.subscribe(my_listener)
    #
    # @example Subscribing to notifications from specific steps
    #   my_transaction.subscirbe(some_step: my_listener, another_step: another_listener)
    #
    # Notifications are implemented using the [Wisper](wisper) gem.
    #
    # [wisper]: https://rubygems.org/gems/wisper
    #
    # @param listeners [Object, Hash{Symbol => Object}] the listener object or hash of steps and listeners
    #
    # @api public
    def subscribe(listeners)
      if listeners.is_a?(Hash)
        listeners.each do |step_name, listener|
          steps.detect { |step| step.step_name == step_name }.subscribe(listener)
        end
      else
        steps.each do |step|
          step.subscribe(listeners)
        end
      end

      self
    end

    private

    def assert_valid_options(options)
      options.each_key do |step_name|
        unless steps.map(&:step_name).include?(step_name)
          raise ArgumentError, "+#{step_name}+ is not a valid step name"
        end
      end
    end

    def assert_options_satisfy_step_arity(options)
      steps.each do |step|
        args_required = step.arity >= 0 ? step.arity : ~step.arity
        args_supplied = options.fetch(step.step_name, []).length + 1 # add 1 for main `input`

        if args_required > args_supplied
          raise ArgumentError, "not enough options for step +#{step.step_name}+"
        end
      end
    end

    def steps_with_options_applied(options)
      steps.map { |step|
        if (args = options[step.step_name])
          step.with_call_args(*args)
        else
          step
        end
      }
    end
  end
end
