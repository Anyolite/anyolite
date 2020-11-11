# Reference to a mruby class
class MrbClass
  @class_ptr : MrbInternal::RClass*

  def initialize(@mrb : MrbState, @name : String, superclass : MrbClass | Nil = nil, @under : MrbModule | MrbClass | Nil = nil)
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
