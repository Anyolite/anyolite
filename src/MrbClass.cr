class MrbClass
  def initialize(@mrb : MrbState, @name : String, superclass : MrbClass | Nil = nil)
    actual_superclass = superclass ? superclass : MrbInternal.get_object_class(@mrb)
    @class_ptr = MrbInternal.mrb_define_class(@mrb, @name, actual_superclass)
  end

  def to_unsafe
    return @class_ptr
  end
end
