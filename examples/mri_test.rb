puts MRITest.do_something(13, "Crystals")
puts MRITest.do_something(13)

dummy = MRITest::MRITestClass.new(name: "Dummy")
puts "Name of dummy is: #{dummy.name}"

unknown = MRITest::MRITestClass.new
dummy.greet(unknown)
unknown.greet(dummy)

child = dummy.create_child_with(unknown)
dummy.greet(child)
unknown.greet(child)
dummy.greet(MRITest::MRITestClass.new(name: 1234))

#require_relative "./test.rb"
require_relative "./hp_example.rb"

GC.start

puts "End of MRI script"