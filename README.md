# Anyolite

Anyolite is a Crystal shard which adds a fully functional mruby interpreter to Crystal.

![Test](https://github.com/Anyolite/anyolite/workflows/Test/badge.svg)

![Release](https://img.shields.io/github/v/release/Anyolite/anyolite)
![ReleaseDate](https://img.shields.io/github/release-date/Anyolite/anyolite)

![License](https://img.shields.io/github/license/Anyolite/anyolite)

# Description

Anyolite allows for wrapping Crystal classes and functions into mruby with little effort.
This way, mruby can be used as a scripting language to Crystal projects, with the major advantage of a similar syntax.

This project is currently in active development, so please report any bugs or missing relevant features.

# Features

* Bindings to an mruby interpreter
* Wrapping of nearly arbitrary Crystal classes and methods to mruby
* Easy syntax without unnecessary boilerplate code
* Simple system to prevent garbage collector conflicts
* Support for keyword arguments and default values
* Objects, arrays, hashes, structs, enums and unions as function arguments and return values are completely valid
* Block arguments can also be wrapped
* Methods and constants can be excluded, modified or renamed with annotations

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

If you want to use other options for Anyolite, you can set `ANYOLITE_CONFIG_PATH` to the filename of a JSON config file,
which allows for changing multiple options when installing the shard. Possible options are:

* `ANYOLITE_BUILD_PATH` - The relative directory in which Anyolite will be built
* `ANYOLITE_RUBY_FORK` - The web address of the mruby repository
* `ANYOLITE_RUBY_RELEASE` - The release tag of the mruby version to be used
* `ANYOLITE_RUBY_DIR` - The relative directory mruby will be installed in
* `ANYOLITE_RUBY_CONFIG` - The config file which is used for building mruby
* `ANYOLITE_GLUE_DIR` - The directory in which helper function C files are located
* `ANYOLITE_COMPILER` - The C compiler used for building Anyolite

# How to use

Imagine a Crystal class for a really bad RPG:

```crystal
module TestModule
  class Entity
    property hp : Int32

    def initialize(@hp : Int32)
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

Now, you want to wrap this class in Ruby. All you need to do is to execute the following code in Crystal (current commit; see documentation page for the version of the latest release):

```crystal
require "anyolite"

Anyolite::RbInterpreter.create do |rb|
  Anyolite.wrap(rb, TestModule)

  rb.load_script_from_file("examples/hp_example.rb")
end
```

Well, that's it already. 
The last line in the block calls the following example script:

```ruby
a = TestModule::Entity.new(hp: 20)
a.damage(diff: 13)
puts a.hp

b = TestModule::Entity.new(hp: 10)
a.absorb_hp_from(other: b)
puts a.hp
puts b.hp
b.yell(sound: 'Ouch, you stole my HP!', loud: true)
a.yell(sound: 'Well, take better care of your public attributes!')
```

The example above gives a good overview over the things you can already do with Anyolite.
More features will be added in the future.

# Limitations

## Hard limitations

These limitations can not be circumvented using other methods.
It might be possible to remove them in future versions, but for
now they are potential roadblocks.

* Currently, Anyolite does not work on Windows due to Crystal compiler bugs
* Anyolite is only compatible with mruby 3 at the current time

## Soft limitations

The limitations here do not have a trivial solution (yet), but with some tricks and
tools from Anyolite it should technically be possible to circumvent them. If one
of these does definitely not work, but you need them to, please feel free to open an issue.

* Pointers are technically supported but unsafe
* Procs as arguments are not directly supported (block arguments are, however)
* Symbols do not work due to their compiletime nature in Crystal
* Only one function with the same name can be wrapped
* Splat arguments and arbitrary keywords are not possible due to their reliance on symbols
* Keywords will always be given to functions, even if optional (then with default values)
* Non-keyword function arguments are always set to their default values before receiving their final values
* Default arguments need to be specialized with their full class and module path in order to work
* Some union and generic types need to be specialized with their full path
* Private constants need to be excluded in order to prevent errors

# Why this name?

https://en.wikipedia.org/wiki/Anyolite

In short, it is a rare variant of the crystalline mineral called zoisite, with ruby and other crystal shards (of pargasite) embedded.

The term 'anyoli' means 'green' in the Maasai language, thus naming 'anyolite'.

# Roadmap

## Upcoming releases

### Version 0.11.0

This version is planned to be the last feature release before 1.0.0.
Currently, the way its features are going to be implemented is not yet determined,
so it will probably take some time before it will be released.
Some of the features might not even make the release.

* [ ] Options for inherited and/or inheriting classes

### Version 1.0.0

* [ ] Windows support (currently not supported due to problems with Crystal)
* [ ] Crystal specs for testing
* [ ] Documentation of all relevant features and wrappers
* [ ] Mac support (might be possible, not tested yet)
* [ ] More configuration options for the Rakefile
* [ ] Ability to choose between mruby and regular Ruby

### Future ideas (might not actually be possible to implement)

* [ ] Splat argument and/or arbitrary keyword passing
* [ ] Method in mruby to determine owner of object
* [ ] Caching of RbValues in the reference table to avoid duplicate objects
* [ ] Storing of pure ruby objects (and procs?) in GC-safe containers
* [ ] Controlled passing of pointers to ruby using the reference table
* [ ] Option for required/optional block arguments
* [ ] Convert macro body variables to fresh variables
* [ ] Resolve context even in generic type union arguments
