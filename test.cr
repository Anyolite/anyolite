require "./anyolite.cr"

module SomeModule
  def self.test_method(int : Int32, str : String)
    puts "#{str} and #{int}"
  end

  @[MrbWrap::RenameClass("TestStructRenamed")]
  struct TestStruct
    property value : Int32 = -123
    property test : Test = Test.new(-234)

    def mrb_initialize(mrb)
      puts "Struct initialized!"
    end
  end

  @[MrbWrap::SpecializeInstanceMethod(output_this_and_struct, [str : TestStruct])]
  @[MrbWrap::RenameInstanceMethod(output_this_and_struct, "output_together_with")]
  @[MrbWrap::ExcludeInstanceMethod(do_not_wrap_this_either)]
  @[MrbWrap::ExcludeConstant(CONSTANT_NOT_TO_WRAP)]
  @[MrbWrap::RenameConstant(CONSTANT, RUBY_CONSTANT)]
  @[MrbWrap::SpecializeInstanceMethod(method_without_keywords, [arg], [arg : String])]
  @[MrbWrap::SpecializeInstanceMethod(method_with_various_args, nil)]
  class Test

    @[MrbWrap::RenameClass("UnderTestRenamed")]
    class UnderTest
      module DeepUnderTest
        class VeryDeepUnderTest
          def nested_test
            puts "This is a nested test"
          end
        end
      end
    end

    enum TestEnum
      Three = 3
      Four
      Five
      Seven = 7
    end

    struct DeepTestStruct
    end

    property x : Int32 = 0

    @@counter : Int32 = 0

    CONSTANT = "Hello"

    CONSTANT_NOT_TO_WRAP = 123

    def self.increase_counter
      @@counter += 1
    end

    def self.counter
      return @@counter
    end

    def self.give_me_a_struct
      s = TestStruct.new
      s.value = 777
      s.test = Test.new(999)
      s
    end

    @[MrbWrap::WrapWithoutKeywords]
    def self.without_keywords(int : Int32)
      int * 10
    end

    @[MrbWrap::Rename("test")]
    def test_instance_method(int : Int32, bool : Bool, str : String, float : Float32 = 0.4f32)
      puts "Old value is #{@x}"
      a = "Args given for instance method: #{int}, #{bool}, #{str}, #{float}"
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

    def +(other : Test)
      Test.new(@x + other.x)
    end

    @[MrbWrap::Exclude]
    def do_not_wrap_this
    end

    def do_not_wrap_this_either
    end

    @[MrbWrap::Exclude]
    def self.do_not_wrap_this_class_method
    end

    def add(other : Test)
      ret = self + other
    end

    def overload_test(arg : Int32 | String | Bool | Nil | Float32 | Test | Test::TestEnum = "Default String")
      if arg.is_a?(Test)
        puts "Test: A test object with x = #{arg.x}"
      else
        puts "Test: #{arg.inspect}"
      end
    end

    def nilable_test(arg : Int32?)
      puts "Received argument #{arg.inspect}"
    end

    def returns_an_enum
      TestEnum::Five
    end

    def returns_something_random
      if rand < 0.5
        3
      else
        "Hello"
      end
    end

    def method_without_keywords(arg)
      puts "Argument is #{arg}"
    end

    def output_this_and_struct(str : TestStruct)
      puts str
      "#{@x} #{str.value} #{str.test.x}"
    end

    def output_this_and_struct(i : Int32)
      raise "This should not be wrapped"
    end

    @[MrbWrap::Specialize([strvar : String, intvar : Int32, floatvar : Float64 = 0.123, strvarkw : String = "nothing", boolvar : Bool = true, othervar : SomeModule::Test = SomeModule::Test.new(17)])]
    def keyword_test(strvar : String, intvar : Int32, floatvar : Float64 = 0.123, strvarkw : String = "nothing", boolvar : Bool = true, othervar : Test = Test.new(17))
      puts "str = #{strvar}, int = #{intvar}, float = #{floatvar}, stringkw = #{strvarkw}, bool = #{boolvar}, other.x = #{othervar.x}"
    end

    def keyword_test(whatever)
      raise "This should not be wrapped"
    end

    private def private_method
    end

    def method_with_various_args(int_arg : Int)
      puts "Some args"
    end

    def method_with_various_args
      puts "No args"
    end

    # Gets called in mruby unless program crashes
    def mrb_finalize(mrb)
      puts "Mruby destructor called for value #{@x}"
    end
  end

  class Bla
    def initialize
    end
  end
end

#MrbRefTable.set_option(:logging)

MrbState.create do |mrb|
  MrbWrap.wrap_module(mrb, SomeModule, "TestModule")
  MrbWrap.wrap_module_function_with_keywords(mrb, SomeModule, "test_method", SomeModule.test_method, [int : Int32 = 19, str : String])
  MrbWrap.wrap_constant(mrb, SomeModule, "SOME_CONSTANT", "Smile! 😊")

  MrbWrap.wrap(mrb, SomeModule::Bla, under: SomeModule, verbose: true)

  MrbWrap.wrap(mrb, SomeModule::TestStruct, under: SomeModule, verbose: true)

  MrbWrap.wrap(mrb, SomeModule::Test, under: SomeModule, instance_method_exclusions: [:add], verbose: true)
  MrbWrap.wrap_instance_method(mrb, SomeModule::Test, "add", add, [SomeModule::Test])

  mrb.load_script_from_file("examples/test.rb")
end

module TestModule
  class Entity
    property hp : Int32 = 0

    def initialize(@hp : Int32)
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
end

puts "Reference table: #{MrbRefTable.inspect}"
MrbRefTable.reset

puts "------------------------------"

MrbState.create do |mrb|
  MrbWrap.wrap(mrb, TestModule)

  mrb.load_script_from_file("examples/hp_example.rb")
end

puts "Reference table: #{MrbRefTable.inspect}"
