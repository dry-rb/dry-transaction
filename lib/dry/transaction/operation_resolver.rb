module Dry
  module Transaction
    class OperationResolver < Module
      def initialize(container)
        module_exec(container) do |ops_container|
          define_method :initialize do |**kwargs|
            operation_kwargs = self.class.steps.select(&:operation_name).map { |step|
              operation = kwargs.fetch(step.name) {
                if ops_container && ops_container.key?(step.operation_name)
                  ops_container[step.operation_name]
                else
                  nil
                end
              }

              [step.name, operation]
            }.to_h

            super(**kwargs, **operation_kwargs)
          end
        end
      end
    end
  end
end
