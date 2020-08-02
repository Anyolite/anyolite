require "./anyolite.cr"

class Test

  property :x

  def test_instance_method(int : Int32, bool : Bool, str : String)
    puts "Old value is #{@x}"
    a = "Args given for instance method: #{int}, #{bool}, #{str}"
    @x += int
    puts "New value is #{@x}"
    return a
  end

  def initialize
    @x = 3
    puts "Test object initialized with #{@x}"
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
    if @@cache[crystal_class.name]?
      return @@cache[crystal_class.name]
    else
      raise "Uncached class: #{crystal_class}"
    end
  end

end

MrbState.create do |mrb|
  MrbMacro.wrap_class(mrb, Test, "Test")
  MrbMacro.wrap_function(mrb, Test, "foo", ->test_method(Int32, Bool, String))

  # Instance methods are still a bit complicated, but it should be possible to simplify this using a macro
  MrbMacro.wrap_function(mrb, Test, "bar", ->(obj : Test, arg_1 : Int32, arg_2 : Bool, arg_3 : String){obj.test_instance_method(arg_1, arg_2, arg_3)}, [Test, Int32, Bool, String])

  MrbMacro.wrap_constructor(mrb, Test, ->Test.new)

  some_crystal_string = "some crystal string"

  GC.disable

  # Something does not work properly yet
  # This is possibly due to passing the Test instances as values instead of references (?)
  # It needs to be fixed anyway
  mrb.load_string("$a = Test.new")
  mrb.load_string("$b = $a.foo(17, true, 'bla')")
  mrb.load_string("puts $b")
  mrb.load_string("puts $a.bar($a, 19, false, '#{some_crystal_string}')")
  mrb.load_string("puts $a.bar($a, 19, false, '#{some_crystal_string}')")
  mrb.load_string("puts $a.bar($a, 19, false, '#{some_crystal_string}')")
  mrb.load_string("puts $a.bar($a, 19, false, '#{some_crystal_string}')")
  mrb.load_string("puts $a.bar($a, 19, false, '#{some_crystal_string}')")
  
  MrbInternal.mrb_print_error(mrb)
  
  GC.enable
  
end
