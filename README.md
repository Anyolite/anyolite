# Anyolite

Anyolite is a Crystal shard which adds a fully functional mruby interpreter to Crystal.

![Test](https://github.com/Anyolite/anyolite/workflows/Test/badge.svg)

![Release](https://img.shields.io/github/v/release/Anyolite/anyolite)
![ReleaseDate](https://img.shields.io/github/release-date/Anyolite/anyolite)

![License](https://img.shields.io/github/license/Anyolite/anyolite)

# Description

Anyolite allows for wrapping Crystal classes and functions into mruby with little effort.
This way, mruby can be used as a scripting language to Crystal projects, with the major advantage of a similar syntax.

This project is currently in the early development phase, so please report any bugs or missing relevant features.

# Features

* Bindings to an mruby interpreter
* Wrapping of nearly arbitrary Crystal classes and methods to mruby
* Easy syntax without unnecessary bolderplate code
* Support for keyword arguments and default values
* Simple system to prevent garbage collector conflicts

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

* `ANYOLITE_BUILDPATH` - The relative directory in which Anyolite will be built
* `ANYOLITE_MRUBY_FORK` - The web address of the mruby repository
* `ANYOLITE_MRUBY_DIR` - The relative directory mruby will be installed in
* `ANYOLITE_MRUBY_CONFIG_PATH` - The config file which is used for building mruby
* `ANYOLITE_COMPILER` - The C compiler used for building Anyolite

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

Now, you want to wrap this class in Ruby. All you need to do is to execute the following code in Crystal (current commit; see documentation page for the version of the latest release):

```crystal
require "anyolite"

MrbState.create do |mrb|
  MrbWrap.wrap(mrb, TestModule)

  mrb.load_script_from_file("examples/hp_example.rb")
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

* Currently, Anyolite does not work on Windows due to Crystal compiler bugs
* Arrays, hashes and other complex mruby objects are not directly supported
* Configuration options for mruby are relatively limited (yet)
* Default values for unnamed function arguments are limited to integers and floats
* Optional keyword arguments need a default value (can be a different one than the Crystal value, though)
* Keywords will always be given to functions, even if optional (then with default values)
* Splat arguments and arbitrary keywords are not possible due to compiletime symbols in Crystal
* Only one type per argument is allowed

# Why this name?

https://en.wikipedia.org/wiki/Anyolite

In short, it is a rare variant of the crystalline mineral called zoisite, with ruby and other crystal shards (of pargasite) embedded.

The term 'anyoli' means 'green' in the Maasai language, thus naming 'anyolite'.

# Roadmap

## Releases

### Version 0.4.1

#### Usability

* Method names in annotations can be given as strings
* More and better verbose information for wrapping

#### Bugfixes

* Setters can be excluded correctly
* Manually wrapped properties work correctly now
* Correct handling of generic function arguments like Int, Number or Float

### Version 0.4.0

#### Major features

* Easier wrapping of classes and all of their methods and constants
* Annotation to exclude functions from wrapping
* Annotation to specialize functions for wrapping
* Annotation to rename wrapped functions
* Full wrapping of module and class hierarchies

#### Breaking changes

* Function names with operators do not include the operator into the ruby name anymore
* Unified module and class cache

#### Usability

* Documentation updates for the new wrapping routines
* Functions with only an operator in their name can now be wrapped using `MrbWrap::Empty`

#### Bugfixes

* Nested classes and modules can now be wrapped reliably

### Version 0.3.0

#### Features

* Crystal structs are wrapped using wrapper objects

#### Breaking changes

* Struct hash values as object ID replacements are obsolete
* Option hash for reference table instead of flags
* Consistent naming for mruby hooks

#### Safety

* Structs with equal hash values do not interfere anymore

#### Usability

* MrbModule instances and Crystal modules can both be used in wrapper methods

### Version 0.2.3

#### Usability

* More options for adjusting reference table

#### Bugfixes

* Fixed reference counter not increasing

### Version 0.2.2

#### Usability

* Added more debugging methods
* Allowed for custom object IDs by defining `mruby_object_id` for a class

#### Bugfixes

* Fixed problems with struct wrapping

### Version 0.2.1

#### Usability
* Operator suffixes as general optional argument for MrbWrap functions
* Option to inspect reference table
* Reference counting in reference table
* Reference table can be cleared

#### Bugfixes
* Fixed structs not being able to be wrapped
* Fixed example in documentation
* Fixed memory leak when returning nontrivial objects in mruby
* Removed constructor limitations for types being able to be used as return values 

### Version 0.2.0

#### Major features

* Keyword argument support
* Support for optional keywords

#### Minor features

* Casting from MrbValue objects to closest Crystal values
* Option to use a JSON config file

#### Breaking changes

* Optional arguments are passed using tuples instead of `MrbWrap::Opt`

#### Safety

* Class checks for arguments
* Checks for correct keyword classes
* Module cache analogous to the class cache

#### Usability

* Simplified some macro functions considerably
* Arguments can be specified consistently as arrays or standalone
* Documentation builds only for releases
* Uniform system for passing optional arguments
* Updated examples and documentation for keyword support

#### Bugfixes

* Fixed erros when naming MrbState instances anything other than 'mrb'

### Version 0.1.1

#### Safety

* Added safeguards for reference table access

#### Bugfixes

* Fixed mruby function return values not being cached
* Fixed minor documentation errors

### Version 0.1.0

#### Major features

* Basic structure
* Ubuntu support
* Wrappers for classes
* Wrappers for modules
* Support for classes in modules
* Wrappers for properties
* Wrappers for instance methods
* Wrappers for module and class methods
* Wrappers for constants
* Optional values for simple argument types
* Crystal GC respects the mruby GC
* Hooks for mruby object creation and deletion
* Simple examples
* Build tests
* Basic documentation

## Upcoming releases

### Version 0.4.2

#### Features

* [X] Support for enums

#### Usability

* [ ] Empty argument list as possible argument for specialization
* [ ] Exclusion message for finalize method
* [ ] Exclusion of private methods
* [ ] Exclusion of to_unsafe
* [ ] Non-fatal runtime errors are triggered in mruby only

#### Bugfixes

* [ ] Proper resolution of class and module hierarchies

### Future updates

* [ ] Windows support (currently not supported due to problems with Crystal)
* [ ] Mac support (might be possible, not tested yet)
* [ ] Compiletime errors for macros
* [ ] Support for more flexible mruby configuration options
* [ ] Arrays as arguments and return values
* [ ] Crystal specs for testing
* [ ] More stable type casting
* [ ] Use Array(TypeDeclaration) instead of Hash for keywords in internal methods
* [ ] Options for inherited and/or inheriting classes
* [ ] Ability to rename the parent module of module hierarchies
* [ ] Support for Crystal 0.36.1

### Possible future updates

* [ ] Other types (Hashes, ...) as arguments and return values
* [ ] Option for passing mruby splat arguments as an array
* [ ] Support for arbitrary keyword arguments as hashes
* [ ] More variety for default parameters for unnamed options
* [ ] Method in mruby to determine owner of object (if possible)
* [ ] Include wrapping of nilable classes (if possible)
* [ ] Better context resolution if necessary
