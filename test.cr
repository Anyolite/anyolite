require "./anyolite.cr"

def dummy_method(*args)
  puts args
  return 123
end

MrbState.create do |mrb|
  test_class = MrbClass.new(mrb, "Test")

  p = MrbMacro.wrap_function(->dummy_method(Int32, Bool, String))

  mrb.define_method("foo", test_class, p)

  mrb.load_string("puts 'Testing Ruby...'")
  mrb.load_string("$a = Test.new")
  mrb.load_string("$b = $a.foo(17, true, 'bla')")
  mrb.load_string("puts $b")

  MrbInternal.mrb_print_error(mrb)
end
