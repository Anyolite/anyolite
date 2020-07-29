require "./anyolite.cr"

# Prototype method for later instance method calls (if it works)
def instance_proc_call(obj, *args)
  a = yield obj, *args
  return a
end

class Test

  def test_method(int : Int32, bool : Bool, str : String)
    a = "Args given: #{int}, #{bool}, #{str}"
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

  a = Test.new
  instance_proc_call(a, 3, true, "Hello") do |obj, *args|
    obj.test_method(*args)
  end

  mrb.load_string("$a = Test.new")
  mrb.load_string("$b = $a.foo(17, true, 'bla')")
  mrb.load_string("puts $b")

  MrbInternal.mrb_print_error(mrb)
end
