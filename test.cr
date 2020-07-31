require "./anyolite.cr"

class Test

  def test_instance_method(int : Int32, bool : Bool, str : String)
    a = "Args given for instance method: #{int}, #{bool}, #{str}"
    return a
  end

end

def test_method(int : Int32, bool : Bool, str : String)
  a = "Args given: #{int}, #{bool}, #{str}"
  return a
end

module MrbClassCache

  @@cache = {} of String => MrbClass

  def self.register(crystal_class : Class, mrb_class : MrbClass)
    @@cache[crystal_class.name] = mrb_class
  end

  def self.get(crystal_class : Class)
    return @@cache[crystal_class.name]
  end

end

MrbState.create do |mrb|
  MrbMacro.wrap_class(mrb, Test, "Test")
  MrbMacro.wrap_function(mrb, Test, "foo", ->test_method(Int32, Bool, String))

  # WARNING: Test objects in Ruby have no internal data yet, so executing this in Ruby will likely segfault
  p = ->(obj : Test, arg_1 : Int32, arg_2 : Bool, arg_3 : String){obj.test_instance_method(arg_1, arg_2, arg_3)}
  MrbMacro.wrap_function(mrb, Test, "bar", ->p(Test, Int32, Bool, String))

  mrb.load_string("$a = Test.new")
  mrb.load_string("$b = $a.foo(17, true, 'bla')")
  mrb.load_string("puts $b")

  MrbInternal.mrb_print_error(mrb)
end
