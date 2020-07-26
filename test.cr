require "./anyolite.cr"

def dummy_method(a, b, c)

end

MrbState.create do |mrb|
  test_class = MrbClass.new(mrb, "Test")

  p = MrbFunc.new do |mrb, self|
    arg_1 = MrbInternal::MrbInt.new(0)
    MrbInternal.mrb_get_args(mrb, "i", pointerof(arg_1))
    MrbCast.return_fixnum(arg_1 * arg_1)
  end

  mrb.define_method("foo", test_class, p)

  puts MrbMacro.format_string(->dummy_method(Int32, Bool, String))

  mrb.load_string("puts 'Testing Ruby...'")
  mrb.load_string("$a = Test.new")
  mrb.load_string("$b = $a.foo(17)")
  mrb.load_string("puts $b")

  MrbInternal.mrb_print_error(mrb)
end
