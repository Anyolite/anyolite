puts "Initiate testing..."

TestFramework.init

start_time = Time.now

# Testing bytecode if enabled
TestFramework.check(test_no: 1, should_be: ["Hello world", 1, 2, 3, 4, 5]) do
  BytecodeTestClass.new("Hello world").do_test(5)
end

# Testing attributes
TestFramework.check(test_no: 2, should_be: 5) do
  a = TestModule::Test.new(x: 5)
  a.x
end

# Testing instance methods and returned arrays
TestFramework.check(test_no: 3, should_be: [19, false, "Example string", 0.4, 5 + 19]) do
  a = TestModule::Test.new(x: 5)
  a.test(int: 19, bool: false, str: 'Example string')
end

# Testing attribute changes using an instance method
TestFramework.check(test_no: 4, should_be: 5 + 19) do
  a = TestModule::Test.new(x: 5)
  a.test(int: 19, bool: false, str: 'Example string')
  a.x
end

# Testing instance methods with keyword arguments
TestFramework.check(test_no: 5, should_be: [19, false, "Example string", 0.5, 5 + 19]) do
  a = TestModule::Test.new(x: 5)
  a.test(int: 19, bool: false, str: 'Example string', float: 0.5)
end

# Testing module methods
TestFramework.check(test_no: 6, should_be: ["Hello", 3]) do
  TestModule.test_method(int: 3, str: "Hello")
end

# Testing custom keyword arguments implemented using Anyolite
TestFramework.check(test_no: 7, should_be: ["World", 19]) do
  TestModule.test_method(str: "World")
end

# Testing attribute setters
TestFramework.check(test_no: 8, should_be: 123) do
  a = TestModule::Test.new(x: 5)
  a.x = 113
  a.x += 10
  a.x
end

# Testing struct attributes
TestFramework.check(test_no: 9, should_be: [-123, -234]) do
  ts = TestModule::TestStructRenamed.new
  [ts.value, ts.test.x]
end

# Testing returned structs
TestFramework.check(test_no: 10, should_be: [777, 999]) do
  some_struct = TestModule::Test.give_me_a_struct
  [some_struct.value, some_struct.test.x]
end

# Testing structs as arguments
TestFramework.check(test_no: 11, should_be: ["5 -123 -234", "5 777 999"]) do
  a = TestModule::Test.new(x: 5)
  ts = TestModule::TestStructRenamed.new
  some_struct = TestModule::Test.give_me_a_struct
  [a.output_together_with(str: ts), a.output_together_with(str: some_struct)]
end

# Testing class methods
TestFramework.check(test_no: 12, should_be: [2, -15]) do
  TestModule::Test.reset_counter
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 5)
  [TestModule::Test.counter, TestModule::Test - 17]
end

# Testing module methods
TestFramework.check(test_no: 13, should_be: "Well, you can't just subtract #{13} from a module...") do
  TestModule::Test::UnderTestRenamed::DeepUnderTest - 13
end

# Testing constants
TestFramework.check(test_no: 14, should_be: "Smile! 😊") do
  TestModule::SOME_CONSTANT
end

# Testing operator methods
TestFramework.check(test_no: 15, should_be: 37) do
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 32)
  (a + b).x
end

# Testing longer keyword methods
TestFramework.check(test_no: 16, should_be: "str = Hi there, int = -121212, float = -0.313, stringkw = 💎, bool = true, other.x = 32") do
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 32)
  a.keyword_test(strvar: "Hi there", intvar: -121212, floatvar: -0.313, strvarkw: "💎", othervar: b)
end

# Testing constants in a more nested type tree
TestFramework.check(test_no: 17, should_be: "Hello") do
  TestModule::Test::RUBY_CONSTANT
end

# Testing methods without keywords
TestFramework.check(test_no: 18, should_be: 120) do
  TestModule::Test.without_keywords(12)
end

# Testing deeply nested type trees
TestFramework.check(test_no: 19, should_be: "This is a nested test") do
  # The absolute, ultimate and ridiculously complicated nesting test  
  TestModule::Test::UnderTestRenamed::DeepUnderTest::VeryDeepUnderTest.new.nested_test
end

# Testing structs and enums
TestFramework.check(test_no: 20, should_be: ["DeepTestStruct", true, true, "Seven"]) do
  struct_test_var = TestModule::Test::DeepTestStruct.new
  enum_test_var = TestModule::Test::TestEnum::Seven
  [struct_test_var.to_s, enum_test_var == TestModule::Test::TestEnum.new(7), enum_test_var != TestModule::Test::TestEnum.new(5), enum_test_var.inspect]  
end

# Testing specialized method
TestFramework.check(test_no: 21, should_be: "No args") do
  a = TestModule::Test.new(x: 5)
  a.method_with_various_args
end

# Testing union arguments
TestFramework.check(test_no: 22, should_be: ["\"Test String\"", "12345.0", "true", "nil", "0.6", "A test object with x = 32", "Four", "A generic test", "\"Default String\""]) do
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 32)
  a_1 = a.overload_test(arg: "Test String")
  a_2 = a.overload_test(arg: 12345)
  a_3 = a.overload_test(arg: true)
  a_4 = a.overload_test(arg: nil)
  a_5 = a.overload_test(arg: 3.0 / 5.0)
  a_6 = a.overload_test(arg: b)
  a_7 = a.overload_test(arg: TestModule::Test::TestEnum::Four)
  a_8 = a.overload_test(arg: TestModule::Test::GTIntInt.new(u: 1, v: 3))
  a_9 = a.overload_test
  [a_1, a_2, a_3, a_4, a_5, a_6, a_7, a_8, a_9]
end

# Testing nilable methods
TestFramework.check(test_no: 23, should_be: ["Received argument 123", "Received argument nil"]) do
  a = TestModule::Test.new(x: 5)
  [a.nilable_test(arg: 123), a.nilable_test(arg: nil)]
end

# Testing struct attributes
TestFramework.check(test_no: 24, should_be: [-123, 4242]) do
  test_struct_thingy = TestModule::TestStructRenamed.new
  initial_value = test_struct_thingy.value
  test_struct_thingy.value = 4242
  modified_value = test_struct_thingy.value
  [initial_value, modified_value]
end

# Testing enum values
TestFramework.check(test_no: 25, should_be: 5) do
  a = TestModule::Test.new(x: 5)
  a.returns_an_enum.value
end

# Testing random return types
TestFramework.check(test_no: 26, should_be: true) do
  a = TestModule::Test.new(x: 5)
  random_value = a.returns_something_random
  puts "Either a string or an int (it's random!): #{random_value}"
  (random_value == 3) || (random_value == "Hello")
end

# Testing generic types
TestFramework.check(test_no: 27, should_be: ["u1 = 3 of Int32, v1 = 5.5 of Float32.", "u1 = 3 of Int32, v1 = 9 of Int32."]) do
  first = TestModule::Test::GTIntFloat.new(u: 1, v: 0.4).test(u1: 3, v1: 5.5)
  second = TestModule::Test::GTIntInt.new(u: 7, v: 10).test(u1: 3, v1: 9)
  [first, second]
end

# Testing generic type functions with generics as arguments
TestFramework.check(test_no: 28, should_be: "This has 1 and 10.0, the other has 2 and 5.0.") do
  TestModule::Test::GTIntFloat.new(u: 1, v: 10.0).compare(other: TestModule::Test::GTIntFloat.new(u: 2, v: 5.0))
end

results = []
results.push "11 - 0.111 - 0.1 - Hello - 1"
results.push "22 - 0.222 - 0.2 - Hello - 32"
results.push "33 - 0.333 - 0.3 - 5 - 2"
results.push "44 - 0.444 - 0.4 - 32 - 32"
results.push "55 - 0.555 - 0.5 - true - 3"
results.push "66 - 0.666 - 0.6 - false - 32"
results.push "77 - 0.777 - 0.7 - Three - 4"
results.push "88 - 0.888 - 0.8 - Four - 32"
results.push "99 - 0.999 - 0.9 - Cookies - 5"
results.push "100 - 0.0 - 1.0 - Cookies - 32"
results.push "0 - 0.0 - 0.0 - SomeModule::Test::GenericTest(Int32, Int32)(@u=1, @v=1) - 32"

# Testing unions as keyword arguments
TestFramework.check(test_no: 29, should_be: results) do
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 32)
  a_1 = a.complicated_method(11, 0.111, 0.1, "Hello", arg_opt_2: 1)
  a_2 = a.complicated_method(22, 0.222, 0.2, "Hello")
  a_3 = a.complicated_method(33, 0.333, 0.3, a, arg_opt_2: 2)
  a_4 = a.complicated_method(44, 0.444, 0.4, b)
  a_5 = a.complicated_method(55, 0.555, 0.5, true, arg_opt_2: 3)
  a_6 = a.complicated_method(66, 0.666, 0.6, false)
  a_7 = a.complicated_method(77, 0.777, 0.7, TestModule::Test::TestEnum::Three, arg_opt_2: 4)
  a_8 = a.complicated_method(88, 0.888, 0.8, TestModule::Test::TestEnum::Four)
  a_9 = a.complicated_method(99, 0.999, 0.9, arg_opt_2: 5)
  a_10 = a.complicated_method(100, 0.000, 1.0)
  a_11 = a.complicated_method(0, 0.0, 0.0, TestModule::Test::GTIntInt.new(u: 1, v: 1))
  [a_1, a_2, a_3, a_4, a_5, a_6, a_7, a_8, a_9, a_10, a_11]
end

# Testing unicode strings
TestFramework.check(test_no: 30, should_be: "😀 for number 1234567") do
  a = TestModule::Test.new(x: 5)
  # TODO: For some reason, this does not work in MRI
  a.inside_mri? ? "😀 for number 1234567" : a.happy😀emoji😀test😀😀😀(arg: 1234567)
end

# Testing equality methods
TestFramework.check(test_no: 31, should_be: [false, true, false, true, false]) do
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 32)
  same_as_a = TestModule::Test.new(x: a.x)

  [a == b, a == same_as_a, a == 10, a == TestModule::Test::TestChild.new(x: a.x), a == TestModule::Test::TestChild.new(x: a.x + 1)]
end

# Testing UInt8 and nil-returning methods
TestFramework.check(test_no: 32, should_be: ["123", NilClass]) do
  a = TestModule::Test.new(x: 5)
  [a.uint_test(arg: 123), a.noreturn_test.class]
end

# Testing indirect overloads
TestFramework.check(test_no: 33, should_be: ["This was an int", "This was a string"]) do
  a = TestModule::Test.new(x: 5)
  [a.overload_cheat_test(12334), a.overload_cheat_test("Something")]
end

# Testing classes in modules
TestFramework.check(test_no: 34, should_be: true) do
  s = TestModule::Bla.new
  s != nil
end

# Testing block calls and storage
TestFramework.check(test_no: 35, should_be: [5, 5, "2010", 2005, 1005, "4010", 2005, 2005, false]) do
  a = TestModule::Test.new(x: 5)

  before_block_storage = a.x
  new_carrier = nil
  
  a.block_store_test do |value|
    new_carrier = value
    value.x += 1000
    value.x * 2
  end

  carrier = nil

  after_block_storage = a.x

  result = a.block_test do |value| 
    carrier = value
    value.x += 1000
    value.x * 2
  end

  after_block_test = a.x
  block_store_call_result = a.block_store_call

  after_block_call = a.x
  carrier_result = new_carrier ? new_carrier.x : new_carrier

  does_this_have_a_block = a.block_store_test

  [before_block_storage, after_block_storage, result, carrier.x, after_block_test, block_store_call_result, after_block_call, carrier_result, does_this_have_a_block]
end

# Testing block methods with yield
TestFramework.check(test_no: 36, should_be: ["1 2", "3", "They said: Hello, There"]) do
  a = TestModule::Test.new(x: 5)

  other_result = a.block_test_2 do |x, y|
    "#{x} #{y}"
  end
  
  other_result_2 = a.block_test_2 do |x, y|
    x + y
  end

  other_result_3 = TestModule::Test.block_test_3(arg: "They said") do |x, y|
    "#{x}, #{y}"
  end

  [other_result, other_result_2, other_result_3]
end

# Testing arrays
TestFramework.check(test_no: 37, should_be: [[2, 4, "HelloHello"], ["Not an array"]]) do
  a = TestModule::Test.new(x: 5)
  [a.array_test(arg: [1, 2, "Hello"]), a.array_test(arg: "Not an array")]
end

# Testing hashes
TestFramework.check(test_no: 38, should_be: {:hello => "Nice", :world => "to see you!", 3 => 15, "test😊" => :very_long_test_symbol}) do
  a = TestModule::Test.new(x: 5)
  a.hash_return_test
end

# Testing unspecified floats
TestFramework.check(test_no: 39, should_be: 3.0) do
  a = TestModule::Test.new(x: 5)
  a.float_test(arg: 3)
end

# Testing chars
TestFramework.check(test_no: 40, should_be: "🌈") do
  a = TestModule::Test.new(x: 5)
  a.char_test(arg: "🌈")
end

results = []
results.push "World"
results.push TestModule::Test.new(x: 32)
results.push "A number"
results.push TestModule::Test.new(x: 5)
results.push "The symbol should become a string"
results.push TestModule::Test::TestEnum::Three

# Testing hash symbols
TestFramework.check(test_no: 41, should_be: results) do
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 32)
  test_hash = {"Hello" => "World", "Test" => b, 12334 => "A number", 999 => a, :test_symbol => "The symbol should become a string", :enum => TestModule::Test::TestEnum::Three}

  result = a.hash_test(arg: test_hash).each do |key, value|
    puts "Ruby: #{key} -> #{value.is_a?(TestModule::Test) ? "Test with x = #{value.x}" : value.is_a?(TestModule::Test::TestEnum) ? value.value : value}"
  end

  [result["Hello"], result["Test"], result[12334], result[999], result[":test_symbol"], result[":enum"]]
end

# Testing pointers
TestFramework.check(test_no: 42, should_be: [1002, 1005, 1005, AnyolitePointer]) do
  a = TestModule::Test.new(x: 5)
  a.x = 1001

  ptr = a.ptr_return_test
  
  a_1 = a.ptr_arg_test(arg: ptr)
  a_2 = a.ptr_star_arg_test(arg: ptr)
  a_3 = a.test_int_or_ptr(arg: ptr)

  [a_1, a_2, a_3, ptr.class]
end

class InheritedTest < TestModule::Test
  def initialize(x: 0, z: "")
    super(x: x)
    @y = x * 2
    @z = z
  end
end

class InheritedContentTest < TestModule::Test::ContentTest
  def initialize(content, another_content)
    super(content: content)
    @another_content = another_content
  end

  def overloaded_content
    content
  end
end

# Testing inheriting wrapped classes
TestFramework.check(test_no: 43, should_be: [789789, 3, 4]) do
  it = InheritedContentTest.new([InheritedTest.new(x: 123456, z: "Hello"), InheritedTest.new(x: 789789, z: "World")], InheritedTest.new(x: 111, z: "Nice day"))
  mt = TestModule::Test::NewContentTest.new(content: [TestModule::Test::TestChild.new(x: 1), InheritedTest.new(x: 2, z: "2")], more_content: [InheritedTest.new(x: 3, z: "3"), InheritedTest.new(x: 4, z: "4")])
  
  # NOTE: This works, but only for methods directly inherited from Test
  # Overloading is therefore possible, but the other content will be cut
  # Overwriting the original content will most likely result in a segmentation fault
  # TODO: Try to prevent this or throw an exception
  
  [it.overloaded_content[1].x, mt.more_content[0].x, mt.more_content[1].x]
end

module TestModule
  class Test
    def method_only_in_ruby(str, int)
      "#{str} #{int}"
    end

    def self.class_method_in_ruby(str, int)
      "Class method with args #{str} and #{int}"
    end
  end
end

# Testing method calls from Crystal
TestFramework.check(test_no: 44, should_be: ["Hello 3", "Class method with args World and 4", true, false, true]) do
  a = TestModule::Test.new(x: 5)

  [a.call_test, a.class_call_test, a.response_test('method_only_in_ruby'), a.response_test('method_not_in_ruby'), a.class_response_test('class_method_in_ruby')]
end

# Testing nested checks for Crystal and Ruby
TestFramework.check(test_no: 45, should_be: "Do I have an identity crisis? Yes.") do
  a = TestModule::Test.new(x: 5)
  # Try to explain in one sentence what that codeline does without losing your brain to the outer gods
  "Do I have an identity crisis? #{a.why_would_you_do_this?('am_i_in_ruby?') ? 'Yes' : 'No'}."
end

# Testing operator methods with boolean arguments
TestFramework.check(test_no: 46, should_be: ["true", "true", "false"]) do
  a = TestModule::Test.new(x: 5)
  [a.bool_setter_test?, a.bool_setter_test?(true), a.bool_setter_test?(false)]
end

# Testing operator methods with keywords
TestFramework.check(test_no: 47, should_be: "6.0") do
  a = TestModule::Test.new(x: 5)
  a.keyword_operator_arg?(arg: 5)
end

# Testing Ruby value references in Crystal
TestFramework.check(test_no: 48, should_be: "Hello and a reference with 1223 were given.") do
  a = TestModule::Test.new(x: 5)
  a.ref_test(str: "Hello", ref: 1223)
end

# Testing struct constructors with custom default values
TestFramework.check(test_no: 49, should_be: [5678, 0.5678, "Default", 89, 0.89, "Something"]) do
  a_1 = TestModule::Test::ValueStruct.new.i
  a_2 = TestModule::Test::ValueStruct.new.f
  a_3 = TestModule::Test::ValueStruct.new.s
  a_4 = TestModule::Test::ValueStruct.new(89, 0.89, "Something").i
  a_5 = TestModule::Test::ValueStruct.new(89, 0.89, "Something").f
  a_6 = TestModule::Test::ValueStruct.new(89, 0.89, "Something").s

  [a_1, a_2, a_3, a_4, a_5, a_6]
end

# Testing inspect methods
TestFramework.check(test_no: 50, should_be: "x is 5") do
  a = TestModule::Test.new(x: 5)
  a.inspect
end

# Testing self as argument type
TestFramework.check(test_no: 51, should_be: "Value is 1 and 2.3") do
  TestModule::Test::GTIntFloat.self_test(other: TestModule::Test::GTIntFloat.new(u: 1, v: 2.3))
end

# Testing equality methods of enums and structs
TestFramework.check(test_no: 52, should_be: [true, true]) do
  [(TestModule::Test::TestEnum.new(3) == TestModule::Test::TestEnum.new(3)), (TestModule::TestStructRenamed.new == TestModule::TestStructRenamed.new)]
end

# Testing inherited contents and inspects
TestFramework.check(test_no: 53, should_be: ["[x is 5, x is 5]", "[x is 32, x is 5, x is 32]"]) do
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 32)
  inherited_content_test = TestModule::Test::NewContentTest.new(content: [a, a], more_content: [b, a, b])
  [inherited_content_test.content.inspect, inherited_content_test.more_content.inspect]
end

# Testing custom hashes
TestFramework.check(test_no: 54, should_be: [213345, 213345]) do
  a = TestModule::Test.new(x: 5)
  b = TestModule::Test.new(x: 32)
  [a.hash, b.hash]
end

# Testing access to instance variables
TestFramework.check(test_no: 55, should_be: [nil, 15667]) do
  a = TestModule::Test.new(x: 5)
  before = a.get_instance_variable(name: "hello")
  a.set_instance_variable_to_int(name: "hello", value: 15667)
  after = a.get_instance_variable(name: "hello")
  [before, after]
end

# Testing Number arguments
TestFramework.check(test_no: 56, should_be: 1.3) do
  a = TestModule::Test.new(x: 5)
  a.num_test(1.3)
end

TestFramework.check(test_no: 57, should_be: [5, 8, 2, 3, 1, 0]) do
  a = TestModule::Test.new(x: 5)
  a_copy = a.dup
  a_1 = a_copy.x

  a_copy.x += 3
  a.x -= 3

  a_2 = a_copy.x
  a_3 = a.x

  enum_orig = TestModule::Test::TestEnum::Three
  enum_copy = enum_orig.dup

  a_4 = enum_copy.value

  intfloat = TestModule::Test::GTIntFloat.new(u: 1, v: 2.3)
  intfloat_copy = intfloat.dup

  intfloat_copy.u -= 1

  a_5 = intfloat.u
  a_6 = intfloat_copy.u

  [a_1, a_2, a_3, a_4, a_5, a_6]
end

final_time = Time.now

puts "Tests done."
puts "Total time for MRI test script: #{(final_time - start_time)} s"

TestFramework.results(raise_if_failures: true)