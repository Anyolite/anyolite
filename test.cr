require "./anyolite.cr"

module SomeModule
  def self.test_method(int : Int32, str : String)
    puts "#{str} and #{int}"
  end
end

class Test
  property x : Int32 = 0

  @@counter : Int32 = 0

  def self.increase_counter
    @@counter += 1
  end

  def self.counter
    return @@counter
  end

  def test_instance_method(int : Int32, bool : Bool, str : String, fl : Float32)
    puts "Old value is #{@x}"
    a = "Args given for instance method: #{int}, #{bool}, #{str}, #{fl}"
    @x += int
    puts "New value is #{@x}"
    return a
  end

  # Gets called in Crystal and mruby
  def initialize(@x : Int32 = 0)
    Test.increase_counter()
    puts "Test object initialized with value #{@x}"
  end

  # Gets called in mruby
  def mrb_initialize(mrb)
    puts "Object registered in mruby"
  end

  # Gets called in Crystal unless program terminates early
  def finalize
    puts "Finalized with value #{@x}"
  end

  def +(other)
    Test.new(@x + other.x)
  end

  def add(other)
    self + other
  end

  def keyword_test(strvar, intvar, *splat, floatvar = 0.123, boolvar : Bool = true, **other)
    puts "str = #{strvar}, int = #{intvar}, splat = #{splat}, float = #{floatvar}, bool = #{boolvar}, other = #{other}"
  end

  # Gets called in mruby unless program crashes
  def mrb_finalize(mrb)
    puts "Mruby destructor called for value #{@x}"
  end
end

Test.new.keyword_test("Hello", -123, true, floatvar: 0.3, boolvar: false, last_arg: "Hello")
# Format string should be "zi*:"
# Args should be contained in:
# - char* (String)
# - mrb_int (Integer)
# - mrb_value* with mrb_int elements (Splat arguments)
# - mrb_value* with mrb_int elements (Keyword arguments)
# - mrb_value (Double splat argument hash)

MrbState.create do |mrb|
  test_module = MrbModule.new(mrb, "TestModule")
  MrbWrap.wrap_module_function(mrb, test_module, "test_method", SomeModule.test_method, [Int32, String])
  MrbWrap.wrap_constant(mrb, test_module, "SOME_CONSTANT", "Smile! 😊")

  MrbWrap.wrap_class(mrb, Test, "Test", under: test_module)
  MrbWrap.wrap_class_method(mrb, Test, "counter", Test.counter)
  MrbWrap.wrap_constructor(mrb, Test, [MrbWrap::Opt(Int32, 0)])
  MrbWrap.wrap_instance_method(mrb, Test, "bar", test_instance_method, [Int32, Bool, String, MrbWrap::Opt(Float32, 0.4)])
  MrbWrap.wrap_instance_method(mrb, Test, "add", add, [Test])
  MrbWrap.wrap_instance_method(mrb, Test, "+", add, [Test])
  MrbWrap.wrap_property(mrb, Test, "x", x, Int32)

  mrb.load_script_from_file("examples/test.rb")
end

class Entity
  property hp : Int32 = 0

  def initialize(@hp)
  end

  def damage(diff : Int32)
    @hp -= diff
  end

  def yell(sound : String, loud : Bool = false)
    if loud
      puts "Entity yelled: #{sound.upcase}"
    else
      puts "Entity yelled: #{sound}"
    end
  end

  def absorb_hp_from(other : Entity)
    @hp += other.hp
    other.hp = 0
  end
end

class Bla
  def initialize
  end
end

MrbState.create do |mrb|
  test_module = MrbModule.new(mrb, "TestModule")

  MrbWrap.wrap_class(mrb, Entity, "Entity", under: test_module)
  MrbWrap.wrap_class(mrb, Bla, "Bla", under: test_module)

  MrbWrap.wrap_constructor(mrb, Entity, [MrbWrap::Opt(Int32, 0)])

  MrbWrap.wrap_property(mrb, Entity, "hp", hp, Int32)

  MrbWrap.wrap_instance_method(mrb, Entity, "damage", damage, [Int32])

  # Crystal does not allow false here, for some reason, so just use 0 and 1
  MrbWrap.wrap_instance_method(mrb, Entity, "yell", yell, [String, MrbWrap::Opt(Bool, 0)])

  MrbWrap.wrap_instance_method(mrb, Entity, "absorb_hp_from", absorb_hp_from, [Entity])

  MrbWrap.wrap_constructor(mrb, Bla)

  mrb.load_script_from_file("examples/hp_example.rb")
end
