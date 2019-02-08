require "dry/transaction/callable"

module Dry
  module Transaction
    # `:input` option controls which previous step outputs are taken
    # as step inputs. Its value must be a list of previous step names
    # or {INITIAL_INPUT_KEY} for the initial transaction input. If it
    # is nil, it defaults to the previous step output. When it is the
    # empty list, it acts like the "continue" (`>>`) monad operation
    # instead of the common bind (`>>=`).
    #
    # @api private
    class StepAdapter
      # Key to reference the initial transaction input from the `:inputs`
      # option.
      INITIAL_INPUT_KEY = :_initial

      def self.[](adapter, operation, options)
        if adapter.is_a?(self)
          adapter.with(operation, options)
        else
          new(adapter, operation, options)
        end
      end

      attr_reader :adapter
      attr_reader :operation
      attr_reader :options

      def initialize(adapter, operation, options)
        @adapter = case adapter
                   when Proc, Method
                     adapter
                   else
                     adapter.method(:call)
                   end

        @operation = Callable[operation]

        @options = options

        @yields = @adapter.
                    parameters.
                    any? { |type, _| type == :block }
      end

      def yields?
        @yields
      end

      def call(args, &block)
        adapter.(operation, options, args, &block)
      end

      def with(operation = self.operation, new_options = {})
        self.class.new(adapter, operation, options.merge(new_options))
      end

      # Selects previous steps outputs to apply to the step from a
      # given accumulated list.
      #
      # @param previous_outputs [Array<Array<Symbol, Result<Any>>>]
      # List of two element tuples [step name, step output].
      #   @example
      #     [
      #       [:process, Success({ name: "Joe" })],
      #       [:persist, Success({ id: 1, name: "Joe" })
      #     ]
      # @return [Array<Any>]
      def inputs(previous_outputs)
        step_names = options[:input]
        return [previous_outputs.last[1]] if step_names.nil?

        step_names.map do |step_name|
          previous_outputs.find do |output|
            output[0] == step_name
          end[1]
        end
      end

      # Arity of inputs of previous steps outputs.
      #
      # @return [Integer]
      def inputs_arity
        step_names = options[:input]

        step_names ? step_names.length : 1
      end
    end
  end
end
