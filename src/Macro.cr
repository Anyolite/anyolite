module Anyolite
  # Helper methods which should not be used for trivial cases in the final version
  module Macro
  end
end

require "./macros/RubyTypes.cr"
require "./macros/ArgTuples.cr"
require "./macros/ArgConversions.cr"
require "./macros/UnionCasts.cr"
require "./macros/RubyConversions.cr"
require "./macros/FunctionCalls.cr"
require "./macros/ObjectAllocations.cr"
require "./macros/Wrappers.cr"
require "./macros/WrapMethodIndex.cr"
require "./macros/WrapAll.cr"
require "./macros/FunctionGenerators.cr"
