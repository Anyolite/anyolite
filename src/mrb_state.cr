class MrbState
  @mrb_ptr : MRubyInternal::MrbState*

  def self.create
    mrb = self.new
    yield mrb
    mrb.close
  end

  def initialize
    @mrb_ptr = MRubyInternal.mrb_open
  end

  def close
    MRubyInternal.mrb_close(@mrb_ptr)
  end

  def to_unsafe
    return @mrb_ptr
  end

  def load_string(str : String)
    MRubyInternal.mrb_load_string(@mrb_ptr, str)
  end

  def define_method(name : String, c : MrbClass, proc : MrbFunc)
    MRubyInternal.mrb_define_method(@mrb_ptr, c, name, proc, 0)
  end
end
