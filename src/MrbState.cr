class MrbState
  @mrb_ptr : MrbInternal::MrbState*

  def self.create
    mrb = self.new
    yield mrb
    mrb.close
  end

  def initialize
    @mrb_ptr = MrbInternal.mrb_open
  end

  def close
    MrbInternal.mrb_close(@mrb_ptr)
  end

  def to_unsafe
    return @mrb_ptr
  end

  def execute_script_line(str : String)
    MrbInternal.execute_script_line(@mrb_ptr, str)
  end

  def load_script_from_file(filename : String)
    MrbInternal.load_script_from_file(@mrb_ptr, filename)
  end

  # TODO: Arg count
  def define_method(name : String, c : MrbClass, proc : MrbFunc)
    MrbInternal.mrb_define_method(@mrb_ptr, c, name, proc, 1)
  end

  def define_module_function(name : String, mod : MrbModule, proc : MrbFunc)
    MrbInternal.mrb_define_module_function(@mrb_ptr, mod, name, proc, 1)
  end

  def define_class_method(name : String, c : MrbClass, proc : MrbFunc)
    MrbInternal.mrb_define_class_method(@mrb_ptr, c, name, proc, 1)
  end
end
