# Anyolite

Anyolite is a Crystal shard which adds a fully functional mruby (or even regular Ruby) interpreter to Crystal.

![Test](https://github.com/Anyolite/anyolite/workflows/Test/badge.svg)

![Release](https://img.shields.io/github/v/release/Anyolite/anyolite)
![ReleaseDate](https://img.shields.io/github/release-date/Anyolite/anyolite)

![License](https://img.shields.io/github/license/Anyolite/anyolite)

# Description

Anyolite allows for wrapping Crystal classes and functions into Ruby with little effort.
This way, Ruby can be used as a scripting language to Crystal projects, with the major advantage of a similar syntax.

Useful links for an overview:
* Demo project: https://github.com/Anyolite/ScapoLite
* Wiki: https://github.com/Anyolite/anyolite/wiki
* Documentation: https://anyolite.github.io/anyolite

# Features

* Bindings to an mruby interpreter
* Near complete support to regular Ruby as alternative implementation (also known as MRI or CRuby)
* Wrapping of nearly arbitrary Crystal classes and methods to Ruby
* Easy syntax without unnecessary boilerplate code
* Simple system to prevent garbage collector conflicts
* Support for keyword arguments and default values
* Objects, arrays, hashes, structs, enums and unions as function arguments and return values are completely valid
* Ruby methods can be called at runtime as long as all their possible return value types are known
* Ruby closures can be handled as regular variables
* Methods and constants can be excluded, modified or renamed with annotations
* Options to compile scripts directly into the executable

# Prerequisites

You need to have the following programs installed (and in your PATH variable, if you are on Windows):
* Ruby (for building mruby)
* Rake (for building the whole project)
* Git (for downloading mruby)
* GCC or Microsoft Visual Studio 19 (for building the object files required for Anyolite, depending on your OS)

## Using regular Ruby instead of mruby

It is possible to use Anyolite with regular Ruby (MRI) instead of mruby. An instruction to install MRI can be found at [Using Ruby instead of mruby](https://github.com/Anyolite/anyolite/wiki/Using-Ruby-instead-of-mruby) in the wiki.

# Installing

Put this shard as a requirement into your shard.yml project file and then call
```bash
shards install
```
from a terminal.

Alternatively, you can clone this repository into the lib folder of your project and run
```bash
rake build_shard
```
manually from a terminal or the MSVC Developer Console (on Windows) to install the shard without using the crystal shards program.

If you want to use other options for Anyolite, visit [Changing build configurations](https://github.com/Anyolite/anyolite/wiki/Changing-build-configurations) in the wiki.

# How to use

Imagine a Crystal class for a really bad RPG:

```crystal
module RPGTest
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
  Anyolite.wrap(rb, RPGTest)

  rb.load_script_from_file("examples/hp_example.rb")
end
```

Well, that's it already. 
The last line in the block calls the following example script:

```ruby
a = RPGTest::Entity.new(hp: 20)
a.damage(diff: 13)
puts a.hp

b = RPGTest::Entity.new(hp: 10)
a.absorb_hp_from(other: b)
puts a.hp
puts b.hp
b.yell(sound: 'Ouch, you stole my HP!', loud: true)
a.yell(sound: 'Well, take better care of your public attributes!')
```

The example above gives a good overview over the things you can already do with Anyolite.
More features will be added in the future.

# Limitations

See [Limitations and solutions](https://github.com/Anyolite/anyolite/wiki/Limitations-and-solutions) in the Wiki section for a detailed list.

# Why this name?

https://en.wikipedia.org/wiki/Anyolite

In short, it is a rare variant of the crystalline mineral called zoisite, with ruby and other crystal shards (of pargasite) embedded.

The term 'anyoli' means 'green' in the Maasai language, thus naming 'anyolite'.

# Roadmap

## Upcoming releases

### Version 1.1.0

NOTE: This version requires recompilation of mruby and the C files.

NOTE: This version will only work with mruby 3.2.0 and above.
Since 3.2.0 is not out yet, it is highly recommended to either use an older Anyolite
release or the master branch of mruby.

#### Features

* [X] Added direct bindings to `Regex` from Crystal (`Regexp` in Ruby)
* [X] Added option to use a separate Ruby interpreter
* [X] Added safeguard to catch non-fatal Crystal exceptions and raise them as Ruby errors
* [X] Added option to transform procs into bytecode
* [X] Added function to disable external program execution
* [ ] Updated to mruby 3.2.0 (as soon as it releases)

#### Usability

* [X] Updated mruby config file to use `libucrt` instead of `msvcrt`
* [X] Discarded old and problematic Regex mruby gem
* [X] Made arguments for `Anyolite.call_rb_method_of_object` optional
* [X] Added automatic conversion from Ruby class names to class objects in method callers
* [X] Improved testing script
* [X] Added check for `RbValue` and `RbRef` to some macro methods
* [X] Added ability to pass Ruby blocks via Crystal to Ruby function calls 
* [X] Added some internal methods to mruby to handle fibers
* [X] Added some exception checking methods

#### Bugfixes

* [X] Fixed error when running `shards install` on Windows
* [X] Fixed compilation warning messages for Windows
* [X] Fixed problems with Regexes due to PCRE conflicts
* [X] Fixed problems with Anyolite on Crystal 1.5.1
* [X] Unspecified arguments now always correctly throw warnings instead of confusing errors
* [X] Fixed compiletime error when casting to `Char`
* [X] Fixed errors when passing certain name arguments to Macros for calling Ruby functions 
* [X] Fixed `Anyolite.call_rb_method_of_object` argument `args` not being optional
* [X] Fixed problems with Regex in recent Crystal commits
* [X] Fixed linker error due to typo in mruby bindings for block functions
* [X] Fixed crash when casting Ruby numbers into objects in some cases
* [X] Fixed script lines not printing exceptions

### Later releases

* [ ] Automated generation of Ruby documentations for wrapped functions
* [ ] MRI support on Windows (does currently not work for some reason)
* [ ] Mac support and continuous integration
* [ ] Support for bindings using `Data` and `Struct` from Ruby

### Wishlist, entries might not be possible to implement

* [ ] Splat argument and/or arbitrary keyword passing
* [ ] Support for slices and bytes
* [ ] Classes as argument type
* [ ] Resolve context even in generic type union arguments
* [ ] General improvement of type resolution
* [ ] Bignum support
* [ ] Range support
