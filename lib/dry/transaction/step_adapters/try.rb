# frozen_string_literal: true

require "dry/transaction/errors"

module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Try
        include Dry::Monads[:result]

        def call(operation, options, args)
          unless options[:catch]
            raise MissingCatchListError, options[:step_name]
          end

          result = operation.(*args)
          Success(result)
        rescue *Array(options[:catch]) => exception
          e = options[:raise].new(exception.message) if options[:raise]
          Failure(e)
        end
      end

      register :try, Try.new
    end
  end
end
