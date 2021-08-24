class SomeArbitraryClass
  attr_reader :array
  
  def initialize(array)
    @array = array
  end
end

puts "Test value: #{SomeArbitraryClass.new([1, 2, "three"]).array[2]}"

puts TestModule::SOME_CONSTANT

require_relative "./test.rb"