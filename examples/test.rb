a = TestModule::Test.new(x: 5)
b = TestModule::Test.new(x: 32)

s = TestModule::Bla.new

puts a.test(int: 19, bool: false, str: 'Example string')
puts a.test(int: 19, bool: false, str: 'Example string', float: 0.5)

TestModule.test_method(int: 3, str: "Hello")

puts "Value getter returns #{a.x}"
puts "Adding..."
a.x = 123
puts "Value getter returns #{a.x}"

ts = TestModule::TestStruct.new
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
TestModule::Test::UnderTest::DeepUnderTest::VeryDeepUnderTest.new.nested_test

struct_test_var = TestModule::Test::DeepTestStruct.new
puts "Struct test var: #{struct_test_var}"

enum_test_var = TestModule::Test::TestEnum::Seven
puts "Enum test var: #{enum_test_var.value}"

a.method_with_various_args