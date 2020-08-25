# Anyolite

Anyolite is a Crystal shard which adds a fully functional mruby interpreter to Crystal.

![Test](https://github.com/Anyolite/anyolite/workflows/Test/badge.svg)

![Release](https://img.shields.io/github/v/release/Anyolite/anyolite)
![ReleaseDate](https://img.shields.io/github/release-date/Anyolite/anyolite)

![License](https://img.shields.io/github/license/Anyolite/anyolite)

# Description

Anyolite allows for wrapping Crystal classes and functions into mruby with little effort.
This way, mruby can be used as a scripting language to Crystal projects, with the major advantage of a similar syntax.

Anyolite also ensures that the Crystal garbage collector does not delete the mruby objects, avoiding memory leaks.

This project is currently in the early development phase, so please report any bugs or missing relevant features.

# Prerequisites

You need to have the following programs installed (and in your PATH variable, if you are on Windows):
* Ruby (for building mruby)
* Rake (for building the whole project)
* Bison (for building mruby)
* Git (for downloading mruby)
* GCC or Microsoft Visual Studio 19 (for building the object files required for Anyolite, depending on your OS)

# Installing

Put this shard as a requirement into your shard.yml project file and then call
```bash
shards install
```
from a terminal or the MSVC Developer Console (on Windows).

Alternatively, you can clone this repository into the lib folder of your project and run
```bash
rake build_shard
```
manually to install the shard without using the crystal shards program.

# How to use

Imagine a Crystal class for a really bad RPG:

```crystal
module TestModule
  class Entity
    property hp : Int32 = 0

    def initialize(@hp)
    end

    def damage(diff : Int32)
      @hp -= diff
    end

    def yell(sound : String, loud : Bool = false)
      if loud
        puts "Entity yelled: #{sound.upcase}"
      else
        puts "Entity yelled: #{sound}"
      end
    end

    def absorb_hp_from(other : Entity)
      @hp += other.hp
      other.hp = 0
    end
  end
end
```

Now, you want to wrap this class in Ruby. All you need to do is to execute the following code in Crystal:

```crystal
require "anyolite"

MrbState.create do |mrb|
  test_module = MrbModule.new(mrb, "TestModule")
  MrbWrap.wrap_class(mrb, Entity, "Entity", under: test_module)
  
  MrbWrap.wrap_constructor(mrb, Entity, [MrbWrap::Opt(Int32, 0)])

  MrbWrap.wrap_property(mrb, Entity, "hp", hp, Int32)
  
  MrbWrap.wrap_instance_method(mrb, Entity, "damage", damage, [Int32])

  # Crystal does not allow false here, for some reason, so just use 0 and 1
  MrbWrap.wrap_instance_method(mrb, Entity, "yell", yell, [String, MrbWrap::Opt(Bool, 0)])

  MrbWrap.wrap_instance_method(mrb, Entity, "absorb_hp_from", absorb_hp_from, [Entity])

  mrb.load_script_from_file("examples/hp_example.rb")
end
```

The last line in the block calls the following example script:

```ruby
a = TestModule::Entity.new(20)
a.damage(13)
puts a.hp

b = TestModule::Entity.new(10)
a.absorb_hp_from(b)
puts a.hp
puts b.hp
b.yell('Ouch, you stole my HP!', true)
a.yell('Well, take better care of your public attributes!')
```

The syntax stays mostly the same as in Crystal, except for the keyword arguments.
These might be added in the future, but technically you can always wrap the generated methods in pure Ruby methods with keywords.

The example above gives a good overview over the things you can already do with Anyolite.
More features will be added in the future.

# Roadmap

## Releases

### Version 0.1.0

* [X] Basic structure
* [X] Ubuntu support
* [X] Wrappers for classes
* [X] Wrappers for modules
* [X] Support for classes in modules
* [X] Wrappers for properties
* [X] Wrappers for instance methods
* [X] Wrappers for module and class methods
* [X] Wrappers for constants
* [X] Optional values for simple argument types
* [X] Crystal GC respects the mruby GC
* [X] Hooks for mruby object creation and deletion
* [X] Simple examples
* [X] Build tests
* [X] Basic documentation

## Upcoming releases

### Version 0.2.0

* [ ] Keyword argument support
* [ ] Module cache analogus to the class cache
* [ ] Arguments can be specified consistently as arrays or standalone

### Future updates

* [ ] Windows support (currently not supported due to problems with Crystal)
* [ ] Mac support (might be possible, not tested yet)

### Possible future updates

* [ ] Flag for Crystal-owned objects
* [ ] Other types (Hashes, ...) as arguments and return values
* [ ] Arrays as arguments and return values

# Why this name?

https://en.wikipedia.org/wiki/Anyolite

In short, it is a rare variant of the crystalline mineral called zoisite, with a ruby and crystal shards (of pargasite) embedded.

The term 'anyoli' means 'green' in the Maasai language, thus naming 'anyolite'.
