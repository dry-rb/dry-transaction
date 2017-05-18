module Dry
  module Transaction
    module InstanceMethods
      attr_reader :steps
      attr_reader :operations
      attr_reader :matcher

      def initialize(matcher: ResultMatcher, steps: (self.class.steps), **operations)
        @steps = steps.map { |step|
          operation = methods.include?(step.step_name) ? method(step.step_name) : operations[step.step_name]
          step = step.with(operation: operation) if operation
          step
        }
        @operations = operations
        @matcher = matcher
      end

      def call(input, &block)
        assert_step_arity

        result = steps.inject(Dry::Monads.Right(input), :bind)

        if block
          matcher.(result, &block)
        else
          result.or { |step_failure|
            # Unwrap the value from the StepFailure and return it directly
            Dry::Monads.Left(step_failure.value)
          }
        end
      end

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
      end

      def with_step_args(**step_args)
        assert_valid_step_args(step_args)

        new_steps = steps.map { |step|
          if step_args[step.step_name]
            step.with(call_args: step_args[step.step_name])
          else
            step
          end
        }

        self.class.new(matcher: matcher, steps: new_steps, **operations)
      end

      def prepend(other = nil, **options, &block)
        other = accept_or_build_transaction(other, **options, &block)

        self.class.new(matcher: matcher, steps: other.steps + steps)
      end

      def append(other = nil, **options, &block)
        other = accept_or_build_transaction(other, **options, &block)

        self.class.new(matcher: matcher, steps: steps + other.steps)
      end

      def insert(other = nil, before: nil, after: nil, **options, &block)
        insertion_step = before || after
        match_insertion_step = proc { |step| step.step_name == insertion_step }

        unless steps.any?(&match_insertion_step)
          raise ArgumentError, "+#{insertion_step}+ is not a valid step name"
        end

        other = accept_or_build_transaction(other, **options, &block)
        index = steps.index(&match_insertion_step) + (after ? 1 : 0)

        self.class.new(matcher: matcher, steps: steps.dup.insert(index, *other.steps))
      end

      def remove(*steps_to_remove)
        new_steps = steps.reject { |step| steps_to_remove.include?(step.step_name) }
        self.class.new(matcher: matcher, steps: new_steps)
      end


      private

      def respond_to_missing?(name, _include_private = false)
        steps.any? { |step| step.step_name == name }
      end

      def method_missing(name, *args, &block)
        step = steps.detect { |step| step.step_name == name }
        super unless step

        operation = operations[step.step_name]
        raise NotImplementedError, "no operation +#{step.operation_name}+ defined for step +#{step.step_name}+" unless operation

        operation.(*args, &block)
      end

      private

      # @param options [Hash] step arguments keyed by step name
      def assert_valid_step_args(step_args)
        step_args.each_key do |step_name|
          unless steps.any? { |step| step.step_name == step_name }
            raise ArgumentError, "+#{step_name}+ is not a valid step name"
          end
        end
      end

      def assert_step_arity
        steps.each do |step|
          num_args_required = step.arity >= 0 ? step.arity : ~step.arity
          num_args_supplied = step.call_args.length + 1 # add 1 for main `input`

          if num_args_required > num_args_supplied
            raise ArgumentError, "not enough arguments supplied for step +#{step.step_name}+"
          end
        end
      end

      def accept_or_build_transaction(other_transaction = nil, **options, &block)
        unless other_transaction || block
          raise ArgumentError, "a transaction must be provided or defined in a block"
        end

        if other_transaction
          other_transaction
        else
          Class.new do
            include Dry.Transaction(container: options[:container])

            instance_eval(&block)
          end.new
        end
      end
    end
  end
end
