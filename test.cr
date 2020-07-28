require "./anyolite.cr"

def dummy_method(*args)
  puts args
  return 123
end

def test_method(int : Int32, bool : Bool, str : String)
  puts str
  return int * int * (bool ? -1 : 1)
end

MrbState.create do |mrb|
  test_class = MrbClass.new(mrb, "Test")

  p = MrbMacro.wrap_function(->test_method(Int32, Bool, String))

  mrb.define_method("foo", test_class, p)

  mrb.load_string("puts 'Testing Ruby...'")
  mrb.load_string("$a = Test.new")
  mrb.load_string("$b = $a.foo(17, true, 'bla')")
  mrb.load_string("puts $b")

  MrbInternal.mrb_print_error(mrb)
end
