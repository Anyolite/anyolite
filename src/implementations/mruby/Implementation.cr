require "./RbCore.cr"
require "./FormatString.cr"

module Anyolite
  module Macro
    macro new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |rb, obj|
        {{b.body}}
      end
    end
  end
end