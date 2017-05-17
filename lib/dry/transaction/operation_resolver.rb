module Dry
  # FIXME: this should be `module Transaciton` now
  module Transaction
    class OperationResolver < Module
      attr_reader :container
      attr_reader :prepended_mod

      def initialize(container)
        @container = container
        @prepended_mod = Module.new

        prepended_mod.module_exec(container) do |container|
          define_method :initialize do |**kwargs|
            operation_kwargs = self.class.steps.select(&:operation_name).map { |step|
              operation = kwargs.fetch(step.operation_name) { container and container[step.operation_name] }

              [step.step_name, operation]
            }.to_h

            super(**kwargs, **operation_kwargs)
          end
        end
      end

      def included(klass)
        klass.prepend(prepended_mod)
      end
    end
  end
end
