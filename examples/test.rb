start_time = Time.now

puts "Initiate testing script..."

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

# Testing overloaded methods
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

# TODO: More tests

a = TestModule::Test.new(x: 5)

puts "Before block storing: #{a.x}"
new_carrier = nil

a.block_store_test do |value|
  new_carrier = value
  value.x += 1000
  value.x * 2
end

b = TestModule::Test.new(x: 32)

s = TestModule::Bla.new

#####

test_struct_thingy = TestModule::TestStructRenamed.new
puts "Initial value: #{test_struct_thingy.value}"
test_struct_thingy.value = 4242
puts "Modified value: #{test_struct_thingy.value}"

puts "This function returns an enum: #{a.returns_an_enum.value}"
puts "Either an int or a string: #{a.returns_something_random.inspect}"

TestModule::Test::GTIntFloat.new(u: 1, v: 0.4).test(u1: 3, v1: 5.5)
TestModule::Test::GTIntInt.new(u: 7, v: 10).test(u1: 3, v1: 9)

TestModule::Test::GTIntFloat.new(u: 1, v: 10.0).compare(other: TestModule::Test::GTIntFloat.new(u: 2, v: 5.0))

puts "Results of complicated method: #{a.complicated_method(11, 0.111, 0.1, "Hello", arg_opt_2: 1)}"
puts "Results of complicated method: #{a.complicated_method(22, 0.222, 0.2, "Hello")}"
puts "Results of complicated method: #{a.complicated_method(33, 0.333, 0.3, a, arg_opt_2: 2)}"
puts "Results of complicated method: #{a.complicated_method(44, 0.444, 0.4, b)}"
puts "Results of complicated method: #{a.complicated_method(55, 0.555, 0.5, true, arg_opt_2: 3)}"
puts "Results of complicated method: #{a.complicated_method(66, 0.666, 0.6, false)}"
puts "Results of complicated method: #{a.complicated_method(77, 0.777, 0.7, TestModule::Test::TestEnum::Three, arg_opt_2: 4)}"
puts "Results of complicated method: #{a.complicated_method(88, 0.888, 0.8, TestModule::Test::TestEnum::Four)}"
puts "Results of complicated method: #{a.complicated_method(99, 0.999, 0.9, arg_opt_2: 5)}"
puts "Results of complicated method: #{a.complicated_method(100, 0.000, 1.0)}"
puts "Results of complicated method: #{a.complicated_method(0, 0.0, 0.0, TestModule::Test::GTIntInt.new(u: 1, v: 1))}"

a.happy😀emoji😀test😀😀😀(arg: 1234567) unless a.inside_mri?

same_as_a = TestModule::Test.new(x: a.x)

puts "Are a and b equal? #{a == b}"
puts "Are a and same_as_a equal? #{a == same_as_a}"
puts "Are a and 10 equal? #{a == 10}"
puts "Are a and similar subtest equal? #{a == TestModule::Test::TestChild.new(x: a.x)}"
puts "Are a and other subtest equal? #{a == TestModule::Test::TestChild.new(x: a.x + 1)}"

puts a.uint_test(arg: 123)
puts a.noreturn_test.class

puts a.overload_cheat_test(12334)
puts a.overload_cheat_test("Something")

carrier = nil

puts a.x

result = a.block_test do |value| 
  carrier = value
  value.x += 1000
  value.x * 2
end

puts result
puts carrier.x

other_result = a.block_test_2 do |x, y|
  "#{x} #{y}"
end

other_result_2 = a.block_test_2 do |x, y|
  x + y
end

puts other_result
puts other_result_2

other_result_3 = TestModule::Test.block_test_3(arg: "They said") do |x, y|
  "#{x}, #{y}"
end

puts other_result_3

puts "Array result: #{a.array_test(arg: [1, 2, "Hello"])}"
puts "Other array result: #{a.array_test(arg: "Not an array")}"

puts "Hash result: #{a.hash_return_test}"

puts a.float_test(arg: 3)
puts a.char_test(arg: "🌈")

test_hash = {"Hello" => "World", "Test" => b, 12334 => "A number", 999 => a, :test_symbol => "The symbol should become a string", :enum => TestModule::Test::TestEnum::Three}

a.hash_test(arg: test_hash).each do |key, value|
  puts "Ruby: #{key} -> #{value.is_a?(TestModule::Test) ? "Test with x = #{value.x}" : value.is_a?(TestModule::Test::TestEnum) ? value.value : value}"
end

a.x = 1001

ptr = a.ptr_return_test

puts ptr

puts "Pointer test 1: #{a.ptr_arg_test(arg: ptr)}"
puts "Pointer test 2: #{a.ptr_star_arg_test(arg: ptr)}"
puts "Pointer test 3: #{a.test_int_or_ptr(arg: ptr)}"
puts ptr.class

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

it = InheritedContentTest.new([InheritedTest.new(x: 123456, z: "Hello"), InheritedTest.new(x: 789789, z: "World")], InheritedTest.new(x: 111, z: "Nice day"))
mt = TestModule::Test::NewContentTest.new(content: [TestModule::Test::TestChild.new(x: 1), InheritedTest.new(x: 2, z: "2")], more_content: [InheritedTest.new(x: 3, z: "3"), InheritedTest.new(x: 4, z: "4")])

# NOTE: This works, but only for methods directly inherited from Test
# Overloading is therefore possible, but the other content will be cut
# Overwriting the original content will most likely result in a segmentation fault
# TODO: Try to prevent this or throw an exception
puts it.overloaded_content[1].x
puts mt.more_content[0].x
puts mt.more_content[1].x

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

a.call_test
a.class_call_test

puts "Does a answer to method_only_in_ruby ? #{a.response_test('method_only_in_ruby')}"
puts "Does a answer to method_not_in_ruby ? #{a.response_test('method_not_in_ruby')}"
puts "Does a.class answer to class_method_in_ruby ? #{a.class_response_test('class_method_in_ruby')}"

# Try to explain in one sentence what that codeline does without losing your brain to the outer gods
puts "Do I have an identity crisis? #{a.why_would_you_do_this?('am_i_in_ruby?') ? 'Yes' : 'No'}."

puts "After block storing: #{a.x}"
puts "Block store call result: #{a.block_store_call}"
puts "After block call: #{a.x}"
puts "Carrier result: #{new_carrier ? new_carrier.x : new_carrier}"

puts "Does this have a block? #{a.block_store_test}"

puts a.bool_setter_test?
puts a.bool_setter_test?(true)
puts a.bool_setter_test?(false)

puts a.keyword_operator_arg?(arg: 5)

puts a.ref_test(str: "Hello", ref: 1223)

puts TestModule::Test::ValueStruct.new.i
puts TestModule::Test::ValueStruct.new.f
puts TestModule::Test::ValueStruct.new.s
puts TestModule::Test::ValueStruct.new(89, 0.89, "Something").i
puts TestModule::Test::ValueStruct.new(89, 0.89, "Something").f
puts TestModule::Test::ValueStruct.new(89, 0.89, "Something").s

puts a.inspect

TestModule::Test::GTIntFloat.self_test(other: TestModule::Test::GTIntFloat.new(u: 1, v: 2.3))

puts "Are enums equal: #{TestModule::Test::TestEnum.new(3) == TestModule::Test::TestEnum.new(3)}"
puts "Are structs equal: #{TestModule::TestStructRenamed.new == TestModule::TestStructRenamed.new}"

inherited_content_test = TestModule::Test::NewContentTest.new(content: [a, a], more_content: [b, a, b])

puts "Inherited content test: #{inherited_content_test.content.inspect.gsub("\n", "")} and #{inherited_content_test.more_content.inspect.gsub("\n", "")}"

puts a.hash
puts b.hash

puts a.get_instance_variable(name: "hello")
a.set_instance_variable_to_int(name: "hello", value: 15667)
puts a.get_instance_variable(name: "hello")

a.num_test(1.0)

puts "Testing dup..."

a_copy = a.dup
puts a_copy.x

a_copy.x += 3
a.x -= 3

puts a_copy.x
puts a.x

enum_orig = TestModule::Test::TestEnum::Three
enum_copy = enum_orig.dup

puts enum_copy

intfloat = TestModule::Test::GTIntFloat.new(u: 1, v: 2.3)
intfloat_copy = intfloat.dup

intfloat_copy.u -= 1

puts intfloat.u
puts intfloat_copy.u

puts "Testing done."

final_time = Time.now

puts "Total time for MRI test script: #{(final_time - start_time)} s"
