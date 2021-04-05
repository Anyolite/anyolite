module Anyolite
  # Reference to a mruby class
  class RbClass
    @class_ptr : MrbInternal::RClass*

    def initialize(@mrb : RbInterpreter, @name : String, superclass : RbClass | Nil = nil, @under : RbModule | RbClass | Nil = nil)
      actual_superclass = superclass ? superclass : MrbInternal.get_object_class(@mrb)
      if mod = @under
        @class_ptr = MrbInternal.mrb_define_class_under(@mrb, mod, @name, actual_superclass)
      else
        @class_ptr = MrbInternal.mrb_define_class(@mrb, @name, actual_superclass)
      end
    end

    def to_unsafe
      return @class_ptr
    end
  end
end
