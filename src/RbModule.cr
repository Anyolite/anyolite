module Anyolite
  # Reference to a mruby module
  class RbModule
    @module_ptr : MrbInternal::RClass*

    def initialize(@mrb : RbInterpreter, @name : String, @under : RbModule | RbClass | Nil = nil)
      if mod = @under
        @module_ptr = MrbInternal.mrb_define_module_under(@mrb, mod, @name)
      else
        @module_ptr = MrbInternal.mrb_define_module(@mrb, @name)
      end
    end

    def to_unsafe
      return @module_ptr
    end
  end
end
