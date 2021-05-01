a = TestModule::Test.new(x: 5)
b = TestModule::Test.new(x: 32)

s = TestModule::Bla.new

puts a.test(int: 19, bool: false, str: 'Example string')
puts a.test(int: 19, bool: false, str: 'Example string', float: 0.5)

TestModule.test_method(int: 3, str: "Hello")
TestModule.test_method(str: "World")

puts "Value getter returns #{a.x}"
puts "Adding..."
a.x = 123
puts "Value getter returns #{a.x}"

ts = TestModule::TestStructRenamed.new
puts "Struct value: #{ts.value}"
puts "Struct test: #{ts.test.x}"

some_struct = TestModule::Test.give_me_a_struct
puts "Some struct value: #{some_struct.value}"
puts "Some struct test: #{some_struct.test.x}"

puts "Output: #{a.output_together_with(str: ts)}"
puts "Output: #{a.output_together_with(str: some_struct)}"

puts "Value of Test: #{TestModule::Test.counter}"
puts "Value of Test after adding 17: #{TestModule::Test + 17}"
puts "Value of nested module: #{TestModule::Test::UnderTestRenamed::DeepUnderTest + 13}"

puts "Test constant is: #{TestModule::SOME_CONSTANT}"

puts "Sum is #{(a + b).x}"

a.keyword_test(strvar: "Hi there", intvar: -121212, floatvar: -0.313, strvarkw: "💎", othervar: b)

puts "Test constant: #{TestModule::Test::RUBY_CONSTANT}"

puts TestModule::Test.without_keywords(12)

# The absolute, ultimate and ridiculously complicated nesting test
TestModule::Test::UnderTestRenamed::DeepUnderTest::VeryDeepUnderTest.new.nested_test

struct_test_var = TestModule::Test::DeepTestStruct.new
puts "Struct test var: #{struct_test_var}"

enum_test_var = TestModule::Test::TestEnum::Seven
puts "Enum test var: #{enum_test_var.value}"

a.method_with_various_args

a.overload_test(arg: "Test String")
a.overload_test(arg: 12345)
a.overload_test(arg: true)
a.overload_test(arg: nil)
a.overload_test(arg: 3.0 / 5.0)
a.overload_test(arg: b)
a.overload_test(arg: TestModule::Test::TestEnum::Four)
a.overload_test(arg: TestModule::Test::GTIntInt.new(u: 1, v: 3))
a.overload_test

a.nilable_test(arg: 123)
a.nilable_test(arg: nil)

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

a.happy😀emoji😀test😀😀😀(1234567)

same_as_a = TestModule::Test.new(x: a.x)

puts "Are a and b equal? #{a == b}"
puts "Are a and same_as_a equal? #{a == same_as_a}"

puts a.uint_test(arg: 123)
puts a.noreturn_test.class

puts a.overload_cheat_test(12334)
puts a.overload_cheat_test("Something")

carrier = nil

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

puts "Array result: #{a.array_test([1, 2, "Hello"])}"

puts "Hash result: #{a.hash_return_test}"

puts a.float_test(arg: 3)
puts a.char_test(arg: "🌈")