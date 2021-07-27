require "./RbCore.cr"
require "./FormatString.cr"

module Anyolite
  module Macro
    def self.new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |argc, argv, obj|
        rb = Pointer(Void).null
        {{b}}
      end
    end
  end
end