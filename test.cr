require "./anyolite.cr"

def dummy_method(*args)

end

MrbState.create do |mrb|
  test_class = MrbClass.new(mrb, "Test")

  # TODO: Try this without malloc.
  # TODO: Maybe use macros to directly create the variables?
  # TODO: Otherwise just let it be this way, for now.

  p = MrbFunc.new do |mrb, self|
    args = Tuple.new(Pointer(MrbInternal::MrbInt).malloc(size: 1), Pointer(MrbInternal::MrbBool).malloc(size: 1), Pointer(LibC::Char*).malloc(size: 1))
    format_string = MrbMacro.format_string(->dummy_method(Int32, Bool, String))
    MrbInternal.mrb_get_args(mrb, format_string, args[0], args[1], args[2])
    puts String.new(args[2].value)
    MrbCast.return_fixnum(args[0].value * args[0].value + (args[1].value != 0 ? 1 : 0) * 10)
  end

  mrb.define_method("foo", test_class, p)

  puts MrbMacro.format_string(->dummy_method(Int32, Bool, String))

  mrb.load_string("puts 'Testing Ruby...'")
  mrb.load_string("$a = Test.new")
  mrb.load_string("$b = $a.foo(17, true, 'bla')")
  mrb.load_string("puts $b")

  MrbInternal.mrb_print_error(mrb)
end
