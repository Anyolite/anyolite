# Reference to a mruby module
class MrbModule
  @module_ptr : MrbInternal::RClass*

  def initialize(@mrb : MrbState, @name : String, @under : MrbModule | Nil = nil)
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
