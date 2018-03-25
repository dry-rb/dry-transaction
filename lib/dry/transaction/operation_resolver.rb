module Dry
  module Transaction
    class OperationResolver < Module
      def initialize(container)
        module_exec(container) do |ops_container|
          define_method :resolve_operations do |kwargs|
            self.class.steps.select(&:operation_name).map { |step|
              operation = kwargs.delete(step.step_name) {
                if ops_container && ops_container.key?(step.operation_name)
                  ops_container[step.operation_name]
                else
                  nil
                end
              }

              [step.step_name, operation]
            }.to_h
          end
        end
      end
    end
  end
end
