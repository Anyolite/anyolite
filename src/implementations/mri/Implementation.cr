require "./RbCore.cr"
require "./FormatString.cr"

module Anyolite
  module Macro
    def new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |argc, argv, obj|
        rb = Pointer(Void).null
        {{b.body}}
      end
    end
  end
end