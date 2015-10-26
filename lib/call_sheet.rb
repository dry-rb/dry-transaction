require "deterministic"
require "call_sheet/version"
require "call_sheet/dsl"

# rubocop:disable Style/MethodName
def CallSheet(options = {}, &block)
  CallSheet::DSL.new(options, &block).call
end
