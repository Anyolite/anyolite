a = TestModule::Entity.new(20)
s = TestModule::Bla.new
a.damage(13)
puts a.hp

b = TestModule::Entity.new(10)
a.absorb_hp_from(b)
puts a.hp
puts b.hp
b.yell('Ouch, you stole my HP!', true)
a.yell('Well, take better care of your public attributes!')