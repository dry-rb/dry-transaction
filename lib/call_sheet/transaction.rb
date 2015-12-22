require "call_sheet/result_matcher"

module CallSheet
  class Transaction
    # @api private
    attr_reader :steps

    # @api private
    attr_reader :options

    # @api private
    def initialize(steps, options)
      @steps = steps
      @options = options
    end

    # @api public
    def call(input, call_options = {}, &block)
      assert_valid_options(call_options)
      assert_options_satisfy_step_arity(call_options)

      steps = steps_with_options_applied(call_options)
      result = steps.inject(Right(input), :>>)

      if block
        block.call(ResultMatcher.new(result))
      else
        result
      end
    end
    alias_method :[], :call

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

    # @api public
    def +(other)
      self.class.new(steps + other.steps, options)
    end

    # @api public
    def insert(insert_options, &block)
      insertion_step = insert_options.fetch(:before) { insert_options.fetch(:after) }
      unless steps.map(&:step_name).include?(insertion_step)
        raise ArgumentError, "+#{insertion_step}+ is not a valid step name"
      end

      insert_after = !!insert_options.fetch(:after, false)
      insertion_index = steps.index { |step| step.step_name == insertion_step } + (insert_after ? 1 : 0)

      new_transaction = DSL.new(options, &block).call

      self.class.new(steps.dup.insert(insertion_index, *new_transaction.steps), options)
    end

    # @api public
    def remove(*removed_steps)
      self.class.new(steps.reject { |step| removed_steps.include?(step.step_name) }, options)
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
