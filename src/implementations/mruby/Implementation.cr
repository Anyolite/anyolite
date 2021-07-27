require "./RbCore.cr"
require "./FormatString.cr"

module Anyolite
  module Macro
    def self.new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |rb, obj|
        {{b}}
      end
    end
  end
end