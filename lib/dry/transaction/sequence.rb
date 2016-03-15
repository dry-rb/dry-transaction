require "dry/transaction/result_matcher"

module Dry
  module Transaction
    class Sequence
      # @api private
      attr_reader :steps

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
      # e.g. with a signature like `#call(something_else, input)`, then you
      # must pass the extra arguments as arrays for each step in the options
      # hash.
      #
      # @example Running a transaction
      #   my_transaction.call(some_input)
      #
      # @example Running a transaction with extra step arguments
      #   my_transaction.call(some_input, step_name: [extra_argument])
      #
      # The return value will be the output from the last operation, wrapped
      # in a [Kleisli](kleisli) `Either` object, a `Right` for a successful
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
      # @param listeners [Object, Hash{Symbol => Object}] the listener object or
      #     hash of steps and listeners
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

      # Return a transaction with the steps from the provided transaction
      # prepended onto the beginning of the steps in `self`.
      #
      # @example Prepend an existing transaction
      #   my_transaction = Dry.Transaction(container: container) do
      #     step :first
      #     step :second
      #   end
      #
      #   other_transaction = Dry.Transaction(container: container) do
      #     step :another
      #   end
      #
      #   my_transaction.prepend(other_transaction)
      #
      # @example Prepend a transaction defined inline
      #   my_transaction = Dry.Transaction(container: container) do
      #     step :first
      #     step :second
      #   end
      #
      #   my_transaction.prepend(container: container) do
      #     step :another
      #   end
      #
      # @param other [Dry::Transaction::Sequence] the transaction to prepend.
      #     Optional if you will define a transaction inline via a block.
      # @param options [Hash] the options hash for defining a transaction inline
      #     via a block. Optional if the transaction is passed directly as
      #     `other`.
      # @option options [#[]] :container the operations container
      #
      # @return [Dry::Transaction::Sequence] the modified transaction object
      #
      # @api public
      def prepend(other = nil, **options, &block)
        other = accept_or_build_transaction(other, **options, &block)

        self.class.new(other.steps + steps)
      end

      # Return a transaction with the steps from the provided transaction
      # appended onto the end of the steps in `self`.
      #
      # @example Append an existing transaction
      #   my_transaction = Dry.Transaction(container: container) do
      #     step :first
      #     step :second
      #   end
      #
      #   other_transaction = Dry.Transaction(container: container) do
      #     step :another
      #   end
      #
      #   my_transaction.append(other_transaction)
      #
      # @example Append a transaction defined inline
      #   my_transaction = Dry.Transaction(container: container) do
      #     step :first
      #     step :second
      #   end
      #
      #   my_transaction.append(container: container) do
      #     step :another
      #   end
      #
      # @param other [Dry::Transaction::Sequence] the transaction to append.
      #     Optional if you will define a transaction inline via a block.
      # @param options [Hash] the options hash for defining a transaction inline
      #     via a block. Optional if the transaction is passed directly as
      #     `other`.
      # @option options [#[]] :container the operations container
      #
      # @return [Dry::Transaction::Sequence] the modified transaction object
      #
      # @api public
      def append(other = nil, **options, &block)
        other = accept_or_build_transaction(other, **options, &block)

        self.class.new(steps + other.steps)
      end

      # Return a transaction with the steps from the provided transaction
      # inserted into a specific place among the steps in `self`.
      #
      # Transactions can be inserted either before or after a named step.
      #
      # @example Insert an existing transaction (before a step)
      #   my_transaction = Dry.Transaction(container: container) do
      #     step :first
      #     step :second
      #   end
      #
      #   other_transaction = Dry.Transaction(container: container) do
      #     step :another
      #   end
      #
      #   my_transaction.insert(other_transaction, before: :second)
      #
      # @example Append a transaction defined inline (after a step)
      #   my_transaction = Dry.Transaction(container: container) do
      #     step :first
      #     step :second
      #   end
      #
      #   my_transaction.insert(after: :first, container: container) do
      #     step :another
      #   end
      #
      # @param other [Dry::Transaction::Sequence] the transaction to append.
      #     Optional if you will define a transaction inline via a block.
      # @param before [Symbol] the name of the step before which the
      #     transaction should be inserted (provide either this or `after`)
      # @param after [Symbol] the name of the step after which the transaction
      #     should be inserted (provide either this or `before`)
      # @param options [Hash] the options hash for defining a transaction
      #     inline via a block. Optional if the transaction is passed directly
      #     as `other`.
      # @option options [#[]] :container the operations container
      #
      # @return [Dry::Transaction::Sequence] the modified transaction object
      #
      # @api public
      def insert(other = nil, before: nil, after: nil, **options, &block)
        insertion_step = before || after
        unless steps.map(&:step_name).include?(insertion_step)
          raise ArgumentError, "+#{insertion_step}+ is not a valid step name"
        end

        other = accept_or_build_transaction(other, **options, &block)
        index = steps.index { |step| step.step_name == insertion_step } + (!!after ? 1 : 0)

        self.class.new(steps.dup.insert(index, *other.steps))
      end

      # @overload remove(step, ...)
      #   Return a transaction with steps removed.
      #
      #   @example
      #     my_transaction = Dry.Transaction(container: container) do
      #       step :first
      #       step :second
      #       step :third
      #     end
      #
      #     my_transaction.remove(:first, :third)
      #
      #   @param step [Symbol] the names of a step to remove
      #   @param ... [Symbol] more names of steps to remove
      #
      #   @return [Dry::Transaction::Sequence] the modified transaction object
      #
      #   @api public
      def remove(*steps_to_remove)
        self.class.new(steps.reject { |step| steps_to_remove.include?(step.step_name) })
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

      def accept_or_build_transaction(other_transaction = nil, **options, &block)
        unless other_transaction || block
          raise ArgumentError, "a transaction must be provided or defined in a block"
        end

        other_transaction || DSL.new(**options, &block).call
      end
    end
  end
end
