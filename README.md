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
* Bison (for building mruby)
* Git (for downloading mruby)
* GCC or Microsoft Visual Studio 19 (for building the object files required for Anyolite, depending on your OS)

## Using MRI instead of mruby

If you want to test MRI as implementation, you need these additional programs:
* Autoconf

For MRI on Windows, you also need:
* sed
* patch
* vcpkg with libffi, libyaml, openssl, readline and zlib installed
Note that MRI on Windows is currently not functional.

Compiling Anyolite for MRI requires setting the environment variable `ANYOLITE_CONFIG_PATH` to a valid MRI configuration path (like `config_files/anyolite_config_mri.json`), building the shard and then setting the `anyolite_implementation_ruby_3` and `use_general_object_format_chars` flags for the final compilation.

Support for MRI is still not as fleshed out as mruby. 
Many problems and errors might occur, so mruby is still recommended as the main Ruby implementation for now.

Please report any bugs with MRI, so development can progress smoothly.

### Known issues

* Currently it is only possible to run a single actual Ruby script file
* UTF-8 function and variable names defined in Crystal can lead to crashes in Ruby
* Bytecode compilation functions are not available yet (and might never be)
* Some utility functions from mruby are not available in MRI
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

If you want to use other options for Anyolite, you can set `ANYOLITE_CONFIG_PATH` to the filename of a JSON config file,
which allows for changing multiple options when installing the shard. Possible options are:

* `ANYOLITE_BUILD_PATH` - The relative directory in which Anyolite will be built
* `ANYOLITE_RUBY_FORK` - The web address of the Ruby repository
* `ANYOLITE_RUBY_RELEASE` - The release tag of the Ruby version to be used
* `ANYOLITE_RUBY_DIR` - The relative directory Ruby will be installed in
* `ANYOLITE_RUBY_CONFIG` - The config file which is used for building Ruby
* `ANYOLITE_GLUE_DIR` - The directory in which helper function C files are located
* `ANYOLITE_COMPILER` - The C compiler used for building Anyolite

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

## Hard limitations

These limitations can not be circumvented using other methods.
It might be possible to remove them in future versions, but for
now they are potential roadblocks.

* Only GCC and Visual Studio are officially supported as compilers (others might work if the Rakefile is modified)
* Anyolite for Windows does only work with Crystal version 1.2.0 or higher
* MRI is currently not supported on Windows

## Soft limitations

The limitations here do not have a trivial solution (yet), but with some tricks and
tools from Anyolite it should technically be possible to circumvent them (possible solutions are written below each problem).
If one of these does definitely not work, but you need them to, please feel free to open an issue.

### Procs as arguments are possible, but need special handling

Either annotate the methods using `AddBlockArg` or `StoreBlockArg`.
  
### Symbols do not work fully due to their compiletime nature in Crystal

If all symbols are known beforehand, they can be casted from strings.
  
### Arrays, hashes and strings passed from Crystal to Ruby (or vice versa) are immutable

Do not pass the containers directly, but write special access methods.
  
### Only one function with the same name can be wrapped

Overloading works if you specify the argument type as union and avoid illegal calls.
  
### Splat arguments and arbitrary keywords are not possible due to their reliance on symbols

Passing a hash with strings as keys is a workaround.
  
### Keywords will always be given to functions, even if optional (then with default values)

Try to avoid complex function calls in default arguments.
  
### Non-keyword function arguments are always set to their default values before receiving their final values

Same as above.
  
### Default arguments need to be specialized with their full class and module path in order to work

Use the `Specialize` annotations to change the default values, if needed.
  
### Some union and generic types need to be specialized with their full path

Use the `Specialize` annotations to specify the full path if necessary.
  
### Private constants trigger errors, which can not be prevented by Anyolite

Use the `ExcludeConstant` annotation to exclude private constants.

### Pointers given to Ruby are weak references and therefore not tracked by the garbage collector

Try to avoid exposed pointers wherever possible, otherwise keep track of the referenced objects.

### Integers passed to Ruby are larger than 64 bit

Especially mruby does not directly support large numbers. If really needed, the config file
can be modified to include a BigNum mrbgem, but this is not tested.

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

#### Breaking changes

* [ ] Compacted macro function options into hashes

#### Usability

* [ ] Mac support and continuous integration
* [ ] Unit tests
* [ ] Documentation of all relevant features and wrappers
* [ ] Convert macro body variables to fresh variables wherever possible
* [ ] Code cleanup (especially in the macro section)
* [ ] More compatibility between methods accepting `RbRef` and `RbValue`

#### Bugfixes

* [X] Fixed error when passing blocks to certain method types

### Future feature ideas (might not actually be possible to implement)

* [ ] MRI support on Windows (does currently not work for some reason)
* [ ] Splat argument and/or arbitrary keyword passing
* [ ] Support for slices and bytes
* [ ] Classes as argument type
* [ ] Resolve context even in generic type union arguments
* [ ] General improvement of type resolution
* [ ] Bignum support
