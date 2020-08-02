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

  def initialize(@x : Int32 = 0)
    puts "Test object initialized with value #{@x}"
  end

  def finalize
    puts "Finalized with value #{@x}"
  end
end

MrbState.create do |mrb|
  MrbWrap.wrap_class(mrb, Test, "Test")
  MrbWrap.wrap_constructor(mrb, Test, [Int32])
  MrbWrap.wrap_instance_method(mrb, Test, "bar", test_instance_method, [Int32, Bool, String])
  MrbWrap.wrap_property(mrb, Test, "x", x, Int32)

  GC.disable
  mrb.load_script_from_file("examples/test.rb")
  GC.enable
end
