a = TestModule::Entity.new(hp: 20)
a.damage(diff: 13)
puts a.hp

b = TestModule::Entity.new(hp: 10)
a.absorb_hp_from(other: b)
puts a.hp
puts b.hp
b.yell(sound: 'Ouch, you stole my HP!', loud: true)
a.yell(sound: 'Well, take better care of your public attributes!')