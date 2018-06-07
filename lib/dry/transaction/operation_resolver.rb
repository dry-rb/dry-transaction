module Dry
  module Transaction
    class OperationResolver < Module
      class Operation
        attr_accessor :function, :source

        def initialize(function = nil, source = :injected)
          @function = function
          @source = source
        end
      end

      def initialize(container)
        module_exec(container) do |ops_container|
          define_method :initialize do |**kwargs|
            operation_kwargs = self.class.steps.select(&:operation_name).map { |step|
              operation = kwargs[step.step_name]
              operation = build_operation(kwargs, step, ops_container) unless operation.class == Operation

              [step.step_name, operation]
            }.to_h

            super(**kwargs, **operation_kwargs)
          end

          def build_operation(kwargs, step, ops_container)
            operation = Operation.new
            function = kwargs.fetch(step.step_name) {
              if ops_container && ops_container.key?(step.operation_name)
                operation.source = :container
                ops_container[step.operation_name]
              else
                operation.source = nil
                nil
              end
            }
            operation.function = function
            operation
          end
        end
      end
    end
  end
end
