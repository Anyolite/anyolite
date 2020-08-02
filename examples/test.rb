a = Test.new(5)

puts a.bar(19, false, 'Example string')
puts a.bar(19, false, 'Example string', 0.5)

puts "Value getter returns #{a.x}"
puts "Adding..."
a.x = 123
puts "Value getter returns #{a.x}"
