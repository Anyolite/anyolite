a = TestModule::Test.new(5)
b = TestModule::Test.new(32)

puts a.bar(19, false, 'Example string')
puts a.bar(19, false, 'Example string', 0.5)

TestModule.test_method(3, "Hello")

puts "Value getter returns #{a.x}"
puts "Adding..."
a.x = 123
puts "Value getter returns #{a.x}"

puts "Values of Test: #{TestModule::Test.counter}"

puts "Test constant is: #{TestModule::SOME_CONSTANT}"

puts "Sum is #{(a + b).x}"

a.keyword_test("Hi there", -121212, true, false, false, "Hiiii", floatvar: -0.313, whatever: "XYZ")