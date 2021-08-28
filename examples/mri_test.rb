class SomeArbitraryClass
  attr_reader :array
  
  def initialize(array)
    @array = array
  end
end

puts "Test value: #{SomeArbitraryClass.new([1, 2, "three"]).array[2]}"

puts TestModule::SOME_CONSTANT

puts MRITest.do_something(13, "Crystals")
puts MRITest.do_something(13)

dummy = MRITest::MRITestClass.new("Dummy")
puts "Name of dummy is: #{dummy.name}"

unknown = MRITest::MRITestClass.new
dummy.greet(unknown)
unknown.greet(dummy)

child = dummy.create_child_with(unknown)
dummy.greet(child)
unknown.greet(child)

#require_relative "./test.rb"

GC.start

puts "End of MRI script"