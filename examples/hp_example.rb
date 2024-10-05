a = RPGTest::Entity.new(hp: 20)
a.damage(13)
puts a.hp

b = RPGTest::Entity.new(hp: 10)
a.absorb_hp_from(b)
puts a.hp
puts b.hp
b.yell('Ouch, you stole my HP!', loud: true)
a.yell('Well, take better care of your public attributes!')
