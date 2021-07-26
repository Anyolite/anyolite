class BytecodeTestClass
  def initialize(str)
    @str = str
  end

  def do_test(some_number)
    some_number.times do |i|
      puts "#{@str} test number #{i + 1}"
    end
  end
end

puts "This is a bytecode test file"
