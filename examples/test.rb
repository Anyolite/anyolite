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

puts "Values of Test: #{TestModule::Test.counter}"

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
a.overload_test

a.nilable_test(arg: 123)
a.nilable_test(arg: nil)

test_struct_thingy = TestModule::TestStructRenamed.new
puts "Initial value: #{test_struct_thingy.value}\n"
test_struct_thingy.value = 4242
puts "Modified value: #{test_struct_thingy.value}\n"

puts "This function returns an enum: #{a.returns_an_enum.value}"
puts "Either an int or a string: #{a.returns_something_random.inspect}"

TestModule::Test::GTIntFloat.new.test(u: 3, v: 5.5)