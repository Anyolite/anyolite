module Anyolite
  # Reference to a mruby module
  class RbModule
    @module_ptr : RbCore::RClassPtr

    def initialize(@rb : RbInterpreter, @name : String, @under : RbModule | RbClass | Nil = nil)
      if mod = @under
        @module_ptr = RbCore.rb_define_module_under(@rb, mod, @name)
      else
        @module_ptr = RbCore.rb_define_module(@rb, @name)
      end
    end

    def to_unsafe
      return @module_ptr
    end
  end
end
