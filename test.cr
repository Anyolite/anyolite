require "./anyolite.cr"

# TODO: Pass flags to temporary executable
{% unless flag?(:anyolite_implementation_ruby_3) %}
  Anyolite::Preloader::AtCompiletime.transform_script_to_bytecode("examples/bytecode_test.rb", "examples/bytecode_test.mrb")
  Anyolite::Preloader::AtCompiletime.load_bytecode_file("examples/bytecode_test.mrb")
{% end %}

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
    struct ValueStruct
      property i : Int32 = 1234
      property f : Float32 = 0.1234
      property s : String = "Empty"
  
      @[Anyolite::WrapWithoutKeywords]
      def initialize(new_i : Int = 5678, new_f : Float = 0.5678, new_s : String = "Default")
        @i = new_i.to_i32
        @f = new_f.to_f32
        @s = new_s
      end
    end

    @[Anyolite::RenameClass("UnderTestRenamed")]
    class UnderTest
      module DeepUnderTest
        def self.-(value : Int)
          "Well, you can't just subtract #{value} from a module..."
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

      def self.self_test(other : self)
        puts "Value is #{other.u} and #{other.v}"
      end

      @[Anyolite::WrapWithoutKeywords]
      def +(other : GenericTest(U, V))
        GenericTest(U, V).new(u: @u + other.u, v: @v + other.v)
      end

      def compare(other : GenericTest(U, V))
        puts "This has #{@u} and #{@v}, the other has #{other.u} and #{other.v}."
      end
    end

    alias GTIntFloat = GenericTest(Int32, Float32)
    alias GTIntInt = GenericTest(Int32, Int32)

    property x : Int32 = 0

    @@counter : Int32 = 0

    @@magic_block_store : Anyolite::RbRef | Nil = nil

    CONSTANT = "Hello"

    CONSTANT_NOT_TO_WRAP = 123

    def self.increase_counter
      @@counter += 1
    end

    def self.-(other_value : Int)
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

    def inspect(io : IO)
      io.puts "x is #{@x}"
    end

    # Would all trigger an error!
    # def proc_test(pr : Int32 | (Int32 -> Int32))
    #   pr.call(12)
    # end

    # def proc_test_2(pr : Proc(Int32))
    #   pr.call(12)
    # end

    # def slice_test(s : Slice(Int32))
      
    # end

    # Gets called in Crystal and Ruby
    def initialize(@x : Int32 = 0)
      Test.increase_counter
      puts "Test object initialized with value #{@x}"
    end

    # Gets called in Ruby
    def rb_initialize(rb)
      puts "Object registered in Ruby"
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

    # TODO: This method does not work in MRI for some encoding reason - fix this if possible

    {% unless flag?(:anyolite_implementation_ruby_3) %}
      def happy😀emoji😀test😀😀😀(arg : Int32)
        puts "😀 for number #{arg}"
      end
    {% end %}

    def inside_mri?
      Anyolite.implementation == :mri
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

    def array_test(arg : Array(String | Int32) | String)
      if arg.is_a?(String)
        [arg]
      else
        arg.map{|element| element.to_s * 2}
      end
    end

    def hash_test(arg : Hash(String | Int32, String | SomeModule::Test | SomeModule::Test::UnderTest | SomeModule::Test::TestEnum))
      arg.each do |key, value|
        puts "Crystal: #{key} -> #{value.is_a?(Test) ? "Test with x = #{value.x}" : value}"
      end

      arg
    end

    @[Anyolite::StoreBlockArg]
    def block_test
      block_cache = Anyolite.obtain_given_rb_block
      ret_value = Anyolite.call_rb_block(block_cache, [self], cast_to: Int32)
      ret_value.to_s
    end

    @[Anyolite::AddBlockArg(2, String | Int32)]
    def block_test_2
      return_value = yield 1, 2
      return_value.to_s
    end

    @[Anyolite::AddBlockArg(2, String)]
    def self.block_test_3(arg : String)
      return_value = yield "Hello", "There"
      arg.to_s + ": " + return_value.to_s
    end

    @[Anyolite::StoreBlockArg]
    def block_store_test
      if block_cache = Anyolite.obtain_given_rb_block
        @@magic_block_store = block_cache
        true
      else
        false
      end
    end

    def block_store_call
      if mbs = @@magic_block_store
        ret_value = Anyolite.call_rb_block(mbs, [self], cast_to: Int32)
        ret_value.to_s
      else
        false
      end
    end

    def hash_return_test
      {:hello => "Nice", :world => "to see you!", 3 => 15, "test😊" => :very_long_test_symbol}
    end

    private def private_method
    end

    def method_with_various_args(int_arg : Int)
      puts "Some args"
    end

    def method_with_various_args
      puts "No args"
    end

    @[Anyolite::Specialize([arg : Int | String])]
    @[Anyolite::WrapWithoutKeywords]
    def overload_cheat_test(arg : Int)
      "This was an int"
    end

    @[Anyolite::Exclude]
    def overload_cheat_test(arg : String)
      "This was a string"
    end

    def float_test(arg : Float)
      arg
    end

    def char_test(arg : Char)
      arg
    end

    def bool_setter_test?(arg : Bool = true)
      "#{arg}"
    end

    @[Anyolite::ForceKeywordArg]
    def keyword_operator_arg?(arg : Float)
      "#{arg + 1.0}"
    end

    def am_i_in_ruby?
      Anyolite.referenced_in_ruby?(self)
    end

    @[Anyolite::WrapWithoutKeywords]
    def response_test(name : String)
      Anyolite.does_obj_respond_to(self, name)
    end

    @[Anyolite::WrapWithoutKeywords]
    def class_response_test(name : String)
      Anyolite.does_class_respond_to(self.class, name)
    end

    # This annotation will prevent the method from its global exclusion
    @[Anyolite::Include]
    def call_test
      result = Anyolite.call_rb_method(:method_only_in_ruby, ["Hello", 3], cast_to: String)
      puts result
    end

    def class_call_test
      puts Anyolite.call_rb_method_of_class(self.class, :class_method_in_ruby, ["World", 4], cast_to: String)
    end

    @[Anyolite::WrapWithoutKeywords]
    def why_would_you_do_this?(name : String)
      result = Anyolite.call_rb_method(name, nil, cast_to: String | Int32 | Float32 | Bool | Nil)
      result
    end

    def set_instance_variable_to_int(name : String, value : Int)
      Anyolite.set_iv(self, name, value)
    end

    def get_instance_variable(name : String)
      Anyolite.get_iv(self, name, cast_to: Int?)
    end

    def ref_test(str : String, ref : Anyolite::RbRef)
      converted_arg = Anyolite.cast_to_crystal(ref, Int32?)
      "#{str} and a reference with #{ref.value} (which is #{converted_arg}) were given."
    end

    def hash
      213345
    end

    def ptr_return_test
      pointerof(@x)
    end

    def ptr_arg_test(arg : Pointer(Int32))
      arg.value += 1
      arg.value
    end

    def ptr_star_arg_test(arg : Int32*)
      arg.value += 3
      arg.value
    end

    def test_int_or_ptr(arg : Int32 | Int32*)
      if arg.is_a?(Int32)
        arg
      else
        arg.value
      end
    end

    @[Anyolite::ExcludeInstanceMethod("dup")]
    class TestChild < Test
      property y : String
      
      def initialize(x : Int32 = 0)
        super(x: x)
        @y = x.to_s
      end
    end

    class ContentTest
      def initialize(content : Array(SomeModule::Test))
        @content = content
      end

      def content
        @content
      end
    end

    class NewContentTest < ContentTest
      def initialize(content : Array(SomeModule::Test), more_content : Array(SomeModule::Test))
        super(content: content)
        @more_content = more_content
      end

      def more_content
        @more_content
      end
    end

    # Gets called in Ruby unless program crashes
    def rb_finalize(rb)
      puts "Ruby destructor called for value #{@x}"
    end
  end

  class SubTest < SomeModule::Test
  end

  class Bla
    def initialize
    end
  end
end

# For testing purposes, let's exclude this method globally (and include it again locally)
@[Anyolite::ExcludeInstanceMethod("call_test")]
class Object
end

module RPGTest
  class Entity
    property hp : Int32

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

macro load_test_module()
  Anyolite.wrap_module(rb, SomeModule, "TestModule")
  Anyolite.wrap_module_function_with_keywords(rb, SomeModule, "test_method", SomeModule.test_method, [int : Int32 = 19, str : String])
  Anyolite.wrap_constant(rb, SomeModule, "SOME_CONSTANT", "Smile! 😊")
  Anyolite.wrap(rb, SomeModule::Bla, under: SomeModule, verbose: true)
  Anyolite.wrap(rb, SomeModule::TestStruct, under: SomeModule, verbose: true)
  Anyolite.wrap(rb, SomeModule::Test, under: SomeModule, instance_method_exclusions: [:add], verbose: true)
  Anyolite.wrap_instance_method(rb, SomeModule::Test, "add", add, [SomeModule::Test])
end

{% unless flag?(:anyolite_implementation_ruby_3) %}
  Anyolite::RbInterpreter.create do |rb|
    Anyolite::Preloader.execute_bytecode_from_cache_or_file(rb, "examples/bytecode_test.mrb")
    load_test_module()

    rb.load_script_from_file("examples/test.rb")
  end

  puts "Reference table: #{Anyolite::RbRefTable.inspect}"
  Anyolite::RbRefTable.reset

  puts "------------------------------"

  Anyolite::RbInterpreter.create do |rb|
    Anyolite.wrap(rb, RPGTest)

    rb.load_script_from_file("examples/hp_example.rb")
  end

  puts "Reference table: #{Anyolite::RbRefTable.inspect}"
{% else %}
  Anyolite::RbInterpreter.create do |rb|
    load_test_module()

    Anyolite.wrap(rb, RPGTest)

    rb.execute_script_line("puts TestModule::Test.new(x: 12345).inspect")

    rb.execute_script_line("require_relative './examples/bytecode_test.rb'")

    rb.load_script_from_file("examples/mri_test.rb")

    rb.execute_script_line("puts TestModule::Test.new(x: 67890).inspect")
  end
{% end %}