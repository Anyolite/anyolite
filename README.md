# Anyolite

Anyolite is a Crystal shard which adds a fully functional mruby (or even regular Ruby) interpreter to Crystal.

![Test](https://github.com/Anyolite/anyolite/workflows/Test/badge.svg)

![Release](https://img.shields.io/github/v/release/Anyolite/anyolite)
![ReleaseDate](https://img.shields.io/github/release-date/Anyolite/anyolite)

![License](https://img.shields.io/github/license/Anyolite/anyolite)

# Description

Anyolite allows for wrapping Crystal classes and functions into Ruby with little effort.
This way, Ruby can be used as a scripting language to Crystal projects, with the major advantage of a similar syntax.

This project is currently in active development, so please report any bugs or missing relevant features.

Useful links for an overview:
* Demo project: https://github.com/Anyolite/ScapoLite
* Wiki (under construction): https://github.com/Anyolite/anyolite/wiki
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

## Using MRI instead of mruby

If you want to test MRI as implementation, you need these additional programs:
* Autoconf
* Bison

For MRI on Windows, you also need:
* sed
* patch
* vcpkg with libffi, libyaml, openssl, readline and zlib installed
Note that MRI on Windows is currently not functional.

Compiling Anyolite for MRI requires setting the environment variable `ANYOLITE_CONFIG_PATH` to a valid MRI configuration path (like `config_files/anyolite_config_mri.json`), building the shard and then setting the `anyolite_implementation_ruby_3` and `use_general_object_format_chars` flags for the final compilation.

Support for MRI is still not as fleshed out as mruby. 
Many problems and errors might occur, so mruby is still recommended as the main Ruby implementation for now.

Please report any bugs with MRI, so development can progress smoothly.

### Known issues with MRI

* Currently it is only possible to run a single actual Ruby script file
* UTF-8 function and variable names defined in Crystal can lead to crashes in Ruby
* UTF-8 in general might not work properly (this is no problem in mruby)
* Bytecode compilation functions are not available yet (and might never be)
* Some utility functions from mruby are not available
* Gems need to be installed manually after installing Ruby
* For now, only gcc is supported as compiler

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

If you want to use other options for Anyolite, visit [Changing build configuration](https://github.com/Anyolite/anyolite/wiki/Changing-build-configurations) in the wiki.

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

### Version 1.0.0

This release will mark the first full release of Anyolite, mostly
focussed on platform support, more examples and code quality.

Other versions might still come before this, especially for
bugfixes, but most of the features for a full release of
Anyolite are already implemented.

#### Features

* [ ] Automated generation of Ruby documentations for wrapped functions
* [ ] Return values from evaluated script lines
* [X] Added check methods for Ruby references

#### Breaking changes

* [X] Compacted most macro function options into hashes
* [X] Adds default `inspect` and `to_s` methods to wrapped enums automatically
* [X] Updated mruby to 3.1.0 and MRI to 3.0.4
* [X] Config files now require `rb_minor` argument for MRI specifically

#### Security

* [X] Closing an interpreter will now correctly clean class and type caches
* [X] Fixed segmentation fault when overwriting Crystal content of a class

#### Usability

* [ ] Completed all wiki entries
* [ ] Mac support and continuous integration
* [X] Unit tests in test script
* [X] Converted macro body variables to fresh variables wherever possible
* [X] More compatibility between methods accepting `RbRef` and `RbValue`

#### Bugfixes

* [X] Fixed error when passing blocks to certain method types
* [X] Methods `inspect`, `to_s` and `hash` will now correctly respond to annotations
* [X] Fixed UTF-8 problems in MRI tests
* [X] Fixed crash on returning a `RbRef`

### Future feature ideas (might not actually be possible to implement)

* [ ] MRI support on Windows (does currently not work for some reason)
* [ ] Splat argument and/or arbitrary keyword passing
* [ ] Support for slices and bytes
* [ ] Classes as argument type
* [ ] Resolve context even in generic type union arguments
* [ ] General improvement of type resolution
* [ ] Bignum support
