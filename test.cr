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

MrbState.create do |mrb|
  MrbWrap.wrap_class(mrb, Test, "Test")
  MrbMacro.wrap_constructor(mrb, Test, ->Test.new)
  MrbWrap.wrap_instance_method(mrb, Test, "bar", test_instance_method, [Int32, Bool, String])
  MrbWrap.wrap_property(mrb, Test, "x", x, Int32)

  some_crystal_string = "some crystal string"

  GC.disable

  mrb.load_string("$a = Test.new")
  mrb.load_string("puts $a.bar(19, false, '#{some_crystal_string}')")
  mrb.load_string("puts $a.x")
  mrb.load_string("$a.x = 123")
  mrb.load_string("puts $a.x")

  MrbInternal.mrb_print_error(mrb)

  GC.enable
end
