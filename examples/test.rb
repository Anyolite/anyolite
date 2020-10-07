a = TestModule::Test.new(x: 5)
b = TestModule::Test.new(x: 32)

s = TestModule::Bla.new

puts a.bar(int: 19, bool: false, str: 'Example string')
puts a.bar(int: 19, bool: false, str: 'Example string', float: 0.5)

TestModule.test_method(int: 3, str: "Hello")

puts "Value getter returns #{a.x}"
puts "Adding..."
a.x = 123
puts "Value getter returns #{a.x}"

ts = TestModule::TestStruct.new
puts "Struct value: #{ts.value}"
puts "Struct test: #{ts.test.x}"

puts "Values of Test: #{TestModule::Test.counter}"

puts "Test constant is: #{TestModule::SOME_CONSTANT}"

puts "Sum is #{(a + b).x}"

a.keyword_test("Hi there", -121212, floatvar: -0.313, strvarkw: "💎", othervar: b)
