module CallSheet
  class StepFailure < BasicObject
    attr_reader :__step_name

    def initialize(step_name, object)
      @__step_name = step_name
      @__object = object
    end

    def method_missing(name, *args, &block)
      @__object.send(name, *args, &block)
    end

    def ==(other)
      @__object == other
    end
  end
end
