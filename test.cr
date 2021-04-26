require "./anyolite.cr"

module SomeModule
  def self.test_method(int : Int32, str : String)
    puts "#{str} and #{int}"
  end

  @[Anyolite::RenameClass("TestStructRenamed")]
  struct TestStruct
    property value : Int32 = -123
    property test : Test = Test.new(-234)

    def rb_initialize(rb)
      puts "Struct initialized!"
    end
  end

  @[Anyolite::SpecializeInstanceMethod(output_this_and_struct, [str : TestStruct])]
  @[Anyolite::RenameInstanceMethod(output_this_and_struct, "output_together_with")]
  @[Anyolite::ExcludeInstanceMethod(do_not_wrap_this_either)]
  @[Anyolite::ExcludeConstant(CONSTANT_NOT_TO_WRAP)]
  @[Anyolite::RenameConstant(CONSTANT, RUBY_CONSTANT)]
  @[Anyolite::SpecializeInstanceMethod(method_without_keywords, [arg], [arg : String])]
  @[Anyolite::SpecializeInstanceMethod(method_with_various_args, nil)]
  class Test
    @[Anyolite::RenameClass("UnderTestRenamed")]
    class UnderTest
      module DeepUnderTest
        def self.+(value : Int)
          "Well, you can't just add #{value} to a module..."
        end

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

    @[Anyolite::SpecifyGenericTypes([U, V])]
    struct GenericTest(U, V)

      property u : U 
      property v : V

      def initialize(u : U, v : V)
        @u = u
        @v = v
      end

      def test(u1 : U, v1 : V)
        puts "u1 is #{u1} and has class #{U}, v1 is #{v1} and has class #{V}."
      end

      def compare(other : GenericTest(U, V))
        puts "This has #{@u} and #{@v}, the other has #{other.u} and #{other.v}."
      end
    end

    alias GTIntFloat = GenericTest(Int32, Float32)
    alias GTIntInt = GenericTest(Int32, Int32)

    property x : Int32 = 0

    @@counter : Int32 = 0

    CONSTANT = "Hello"

    CONSTANT_NOT_TO_WRAP = 123

    def self.increase_counter
      @@counter += 1
    end

    def self.+(other_value : Int)
      @@counter + other_value
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

    @[Anyolite::WrapWithoutKeywords]
    def self.without_keywords(int : Int32)
      int * 10
    end

    @[Anyolite::Rename("test")]
    def test_instance_method(int : Int32, bool : Bool, str : String, float : Float32 = 0.4f32)
      puts "Old value is #{@x}"
      a = "Args given for instance method: #{int}, #{bool}, #{str}, #{float}"
      @x += int
      puts "New value is #{@x}"
      return a
    end

    # Would all trigger an error!
    # def pointer_test(p : ::Pointer(Test))
    #   puts "Pointer has value #{p.value.x}"
    # end

    # def proc_test(pr : Int32 | (Int32 -> Int32))
    #   pr.call(12)
    # end

    # def proc_test_2(pr : Proc(Int32))
    #   pr.call(12)
    # end

    # Gets called in Crystal and mruby
    def initialize(@x : Int32 = 0)
      Test.increase_counter
      puts "Test object initialized with value #{@x}"
    end

    # Gets called in mruby
    def rb_initialize(rb)
      puts "Object registered in mruby"
    end

    def ==(other : Test)
      (self.x == other.x)
    end

    # Gets called in Crystal unless program terminates early
    def finalize
      puts "Finalized with value #{@x}"
    end

    def +(other : Test)
      Test.new(@x + other.x)
    end

    @[Anyolite::Exclude]
    def do_not_wrap_this
    end

    def do_not_wrap_this_either
    end

    @[Anyolite::Exclude]
    def self.do_not_wrap_this_class_method
    end

    def add(other : Test)
      ret = self + other
    end

    def uint_test(arg : UInt8)
      arg.to_s
    end

    @[Anyolite::ReturnNil]
    def noreturn_test
      puts "This will still be executed."
      [1]
    end

    def overload_test(arg : Int32 | String | Bool | Nil | Float32 | Test | TestEnum | GenericTest(Int32, Int32) = "Default String")
      if arg.is_a?(Test)
        puts "Test: A test object with x = #{arg.x}"
      elsif arg.is_a?(GenericTest(Int32, Int32))
        puts "Test: A generic test"
      else
        puts "Test: #{arg.inspect}"
      end
    end

    def happy😀emoji😀test😀😀😀(arg : Int32)
      puts "😀 for number #{arg}"
    end

    def nilable_test(arg : Int32?)
      puts "Received argument #{arg.inspect}"
    end

    @[Anyolite::Specialize([arg1 : Int32, arg2 : Float32, arg_req : Float32, arg_opt_1 : String | Test | Bool | TestEnum | GenericTest(Int32, Int32) = "Cookies", arg_opt_2 : Int32 = 32])]
    @[Anyolite::WrapWithoutKeywords(4)]
    def complicated_method(arg1, arg2, arg_req : Float32, arg_opt_1 : String | Test | Bool | TestEnum | GenericTest(Int32, Int32) = "Cookies", arg_opt_2 : Int32 = 32)
      "#{arg1} - #{arg2} - #{arg_req} - #{arg_opt_1.is_a?(Test) ? arg_opt_1.x : arg_opt_1} - #{arg_opt_2}"
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

    @[Anyolite::Specialize([strvar : String, intvar : Int32, floatvar : Float64 = 0.123, strvarkw : String = "nothing", boolvar : Bool = true, othervar : Test = SomeModule::Test.new(17)])]
    def keyword_test(strvar : String, intvar : Int32, floatvar : Float64 = 0.123, strvarkw : String = "nothing", boolvar : Bool = true, othervar : Test = Test.new(17))
      puts "str = #{strvar}, int = #{intvar}, float = #{floatvar}, stringkw = #{strvarkw}, bool = #{boolvar}, other.x = #{othervar.x}"
    end

    def keyword_test(whatever)
      raise "This should not be wrapped"
    end

    # TODO: Make this work
    # def array_test(arg : Test | Array(String | Test))
    #   "Arg is #{arg}"
    # end

    private def private_method
    end

    def method_with_various_args(int_arg : Int)
      puts "Some args"
    end

    def method_with_various_args
      puts "No args"
    end

    # Gets called in mruby unless program crashes
    def rb_finalize(rb)
      puts "Mruby destructor called for value #{@x}"
    end
  end

  class SubTest < SomeModule::Test
  end

  class Bla
    def initialize
    end
  end
end

# Anyolite::RbRefTable.set_option(:logging)

Anyolite::RbInterpreter.create do |rb|
  Anyolite.wrap_module(rb, SomeModule, "TestModule")
  Anyolite.wrap_module_function_with_keywords(rb, SomeModule, "test_method", SomeModule.test_method, [int : Int32 = 19, str : String])
  Anyolite.wrap_constant(rb, SomeModule, "SOME_CONSTANT", "Smile! 😊")

  Anyolite.wrap(rb, SomeModule::Bla, under: SomeModule, verbose: true)

  Anyolite.wrap(rb, SomeModule::TestStruct, under: SomeModule, verbose: true)

  Anyolite.wrap(rb, SomeModule::Test, under: SomeModule, instance_method_exclusions: [:add], verbose: true)
  Anyolite.wrap_instance_method(rb, SomeModule::Test, "add", add, [SomeModule::Test])

  rb.load_script_from_file("examples/test.rb")
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

puts "Reference table: #{Anyolite::RbRefTable.inspect}"
Anyolite::RbRefTable.reset

puts "------------------------------"

Anyolite::RbInterpreter.create do |rb|
  Anyolite.wrap(rb, TestModule)

  rb.load_script_from_file("examples/hp_example.rb")
end

puts "Reference table: #{Anyolite::RbRefTable.inspect}"
