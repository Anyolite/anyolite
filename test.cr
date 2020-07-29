require "./anyolite.cr"

def dummy_method(*args)
  puts args
  return 123
end

def test_method(int : Int32, bool : Bool, str : String)
  a = "Args given: #{int}, #{bool}, #{str}"
  return a
end

MrbState.create do |mrb|
  test_class = MrbClass.new(mrb, "Test")

  MrbMacro.wrap_function(mrb, test_class, "foo", ->test_method(Int32, Bool, String))

  mrb.load_string("$a = Test.new")
  mrb.load_string("$b = $a.foo(17, true, 'bla')")
  mrb.load_string("puts $b")

  MrbInternal.mrb_print_error(mrb)
end
