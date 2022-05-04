class BytecodeTestClass
  def initialize(str)
    @str = str
  end

  def do_test(some_number)
    ret_array = [@str]
    some_number.times do |i|
      ret_array.push i + 1
    end

    ret_array
  end
end

puts "This is a bytecode test file"
