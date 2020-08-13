require "./anyolite.cr"

class Test
  property x : Int32 = 0

  def test_instance_method(int : Int32, bool : Bool, str : String, fl : Float32)
    puts "Old value is #{@x}"
    a = "Args given for instance method: #{int}, #{bool}, #{str}, #{fl}"
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
  test_module = MrbModule.new(mrb, "TestModule")
  MrbWrap.wrap_class(mrb, Test, "Test", under: test_module)
  MrbWrap.wrap_constructor(mrb, Test, [Int32])
  MrbWrap.wrap_instance_method(mrb, Test, "bar", test_instance_method, [Int32, Bool, String, MrbWrap::Opt(Float32, 0.4)])
  MrbWrap.wrap_property(mrb, Test, "x", x, Int32)

  GC.disable
  mrb.load_script_from_file("examples/test.rb")
  GC.enable
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