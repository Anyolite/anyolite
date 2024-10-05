# Changelog

## Releases

### Version 1.1.1

NOTE: This version requires recompilation of mruby and the C files.

NOTE: This version will only work with mruby 3.3.0 and above.

#### Usability

* Updated mruby to 3.3.0
* Updated MRI to 3.0.6
* Added error messages when Rake fails at installing
* Added error messages when mruby/MRI is missing

#### Bugfixes

* Fixed Regex wrapper warnings when running Anyolite with newer Crystal versions
* Fixed warning message when compiling glue files
* Fixed some annotations not working properly

### Version 1.1.0

NOTE: This version requires recompilation of mruby and the C files.

NOTE: This version will only work with mruby 3.2.0 and above.

#### Features

* Added direct bindings to `Regex` from Crystal (`Regexp` in Ruby)
* Added option to use a separate Ruby interpreter
* Added safeguard to catch non-fatal Crystal exceptions and raise them as Ruby errors
* Added option to transform procs into bytecode
* Added function to disable external program execution
* Added interpreter depth counter
* Updated to mruby 3.2.0
* Updated to MRI 3.0.5
* Added backtrace function for mruby
* Added option to fully protect Crystal values from the Ruby GC
* Added standalone wrappers for class properties

#### Usability

* Updated mruby config file to use `libucrt` instead of `msvcrt`
* Discarded old and problematic Regex mruby gem
* Made arguments for `Anyolite.call_rb_method_of_object` optional
* Added automatic conversion from Ruby class names to class objects in method callers
* Improved testing script
* Added check for `RbValue` and `RbRef` to some macro methods
* Added ability to pass Ruby blocks via Crystal to Ruby function calls 
* Added some internal methods to mruby to handle fibers
* Added some exception checking methods
* Added methods to check reference table size
* Removed now optional `Dir` gem from default build config
* Removed need for `use_general_object_format_chars` flag for MRI
* Added global option to use keyword args for optional arguments only

#### Bugfixes

* Fixed error when running `shards install` on Windows
* Fixed compilation warning messages for Windows
* Fixed problems with Regexes due to PCRE conflicts
* Fixed problems with Anyolite on Crystal 1.5.1
* Unspecified arguments now always correctly throw warnings instead of confusing errors
* Fixed compiletime error when casting to `Char`
* Fixed errors when passing certain name arguments to Macros for calling Ruby functions 
* Fixed `Anyolite.call_rb_method_of_object` argument `args` not being optional
* Fixed linker error due to typo in mruby bindings for block functions
* Fixed crash when casting Ruby numbers into objects in some cases
* Fixed script lines not printing exceptions
* Fixed memory leak when calling Ruby scripts and script lines
* Updated tests to account for reworked `inspect` method for enums
* Fixed errors when building Anyolite in a path with spaces
* Fixed problems on Linux when `LD` is set, but `gcc` should compile
* Fixed Crystal functions for accessing global variables in mruby
* Fixed Anyolite to allow enums with types different than `Int32`

### Version 1.0.0

This release marks the first full release of Anyolite, mostly
focussed on code quality, specs and bugfixes.

#### Features

* `Anyolite.eval` can be used to get return values from script lines
* Added check methods for Ruby references

#### Breaking changes

* Compacted most macro function options into hashes
* Adds default `inspect` and `to_s` methods to wrapped enums automatically
* Updated mruby to 3.1.0 and MRI to 3.0.4
* Config files now require `rb_minor` argument for MRI specifically

#### Security

* Closing an interpreter will now correctly clean class and type caches
* Fixed segmentation fault when overwriting Crystal content of a class
* Changed block cache to a stack to avoid overwriting it

#### Usability

* Completed all wiki entries
* Unit tests in test script
* Converted macro body variables to fresh variables wherever possible
* More compatibility between methods accepting `RbRef` and `RbValue`

#### Bugfixes

* Fixed error when passing blocks to certain method types
* Methods `inspect`, `to_s` and `hash` will now correctly respond to annotations
* Fixed UTF-8 problems in MRI tests
* Fixed crash on returning a `RbRef`

### Version 0.17.0

#### Features

* Added annotation to ignore class ancestors

#### Breaking changes

* Renamed `master` branch to `main`
* Changed internal representation of wrapped pointers
* Methods named `==` with no type specification will now return `false` instead of an error if types are incompatible

#### Usability

* Private ancestors will now be ignored automatically

### Version 0.16.1

#### Bugfixes

* Fixed typo in keyword module function wrappers

### Version 0.16.0

#### Features

* Added annotation `DefaultOptionalArgsToKeywordArgs`
* Added option to include bytecode as an array at compiletime
* Added environment variable for changing the mruby config path

#### Usability

* Added more debug information

#### Bugfixes

* Fixed argument error for block methods without arguments
* Fixed build error on Windows while running Github Actions

### Version 0.15.0

#### Features

* Methods for undefining Ruby methods

#### Breaking changes

* Excluding copy methods manually will undefine them from Ruby
* Checks for overflow when casting numbers

#### Usability

* Anyolite now respects exclusions of `dup` and `clone`
* Instance method exclude annotations on classes or modules will exclude them from all inheriting classes
* Include annotations can reverse global exclusions

#### Bugfixes

* Ruby exceptions instead of Crystal exceptions for casting overflows
* Casting to `Number` in mruby produced wrong values

### Version 0.14.0

#### Features

* Support for copying wrapped objects
* Ruby classes and modules can be obtained by name

#### Breaking changes

* All classes and structs automatically wrap the Crystal `dup` function as a copy constructor
* Updates in C glue functions

### Version 0.13.2

#### Features

* Windows support for the default mruby implementation

#### Usability

* CI for MRI (on Linux)

#### Bugfixes

* Fixed macro error for MRI

### Version 0.13.1

#### Bugfixes

* Fixed documentation

### Version 0.13.0

#### Features

* Full MRI Ruby as alternative implementation
* AnyolitePointer helper class for accessing pointers
* Infrastructure to convert script files into bytecode at runtime and compiletime
* Support for setting and getting instance, class and global variables from Crystal

#### Breaking changes

* Changed `RClass*` to `RClassPtr` to allow compatibility with MRI
* Reorganized some macros
* Changed directory structure
* Several code changes for compatibility with MRI
* Block variables for functions definitions have now an underscore in front of them

#### Usability

* Option for defaulting to usage of RbValue as data container for regular arguments
* Alternate build paths are now passed to Anyolite via the environment variable `ANYOLITE_BUILD_PATH`

#### Security

* Error messages for problems when loading scripts or bytecode files

#### Bugfixes

* Alternate build paths are not recognized properly in implementation files
* Fixed typo in name of `rb_str_to_cstr`
* Fixed inconsistent usage of `rb` in many functions

### Version 0.12.0

#### Features

* Automatic wrapping of inherited methods from all non-trivial ancestors
* Direct methods for Ruby error messages
* Usage of `self` as argument type is now allowed
* Option to default to regular args for an entire class

#### Breaking changes

* Renamed `wrap_superclass` to `connect_to_superclass` for clarity
* Excluded wrapping of `dup` and `clone` methods

#### Usability

* Better handling for abstract classes
* Correct handling of `inspect`, `to_s` and `hash` methods
* Enum class method `parse?` is now wrapped automatically
* Better error messages for invalid data pointers
* Default exclusion of unwrappable `<=` class methods for inherited classes
* More consistent debug information
* Error message when trying to wrap slices (for now)
* Added default equality method for structs and enums

#### Bugfixes

* Argument specialization was not possible for operator methods
* Fixed class method exclusions not being recognized
* Fixed config file parsing
* Fixed generic argument parsing for regular arguments
* Fixed error when converting some generics with default arguments
* Default arguments for numeric regular arguments were not processed correctly
* Fixed error when using unions in the style of `Bool?` at some points

### Version 0.11.1

#### Usability

* `RbRef` values can now be used as argument type
* Class inheritance wrapping can be disabled
* Operator methods take arguments using the `ForceKeywordArg` annotations

#### Bugfixes

* Boolean operator methods with default arguments could not be wrapped correctly
* Some wrappers had undocumented options

### Version 0.11.0

#### Features

* Superclass hierarchies will be transferred to Ruby
* Wrapping will skip classes if their superclass was not yet wrapped
* `Anyolite.wrap` will run multiple tries to ensure superclasses being wrapped first
* Classes will only be wrapped twice with `overwrite: true` option
* Objects may check whether they are created in mruby
* Ability to call mruby methods for mruby objects from Crystal by their name
* Ability to call mruby class and module methods from Crystal
* Macros to get the Ruby equivalents of modules and classes
* Checks for Ruby method availability from within Crystal
* Caching of RbValues in the reference table to avoid duplicate objects
* Storing of pure Ruby objects in GC-safe containers
* Annotations to enable obtaining Ruby block arguments
* A method to call contained Ruby procs from their containers in Crystal

#### Breaking changes

* Reference table now has a reference to the interpreter
* Interpreter and reference table operate together now
* Reference table system was reworked completely

#### Usability

* Updated documentation to new features from 0.10.0 and 0.11.0
* If nil is expected, cast everything to it without exceptions
* Simplified internal object casting

### Version 0.10.0

#### Features

* Support for block arguments
* Support for array arguments
* Support for hash arguments
* Support for symbols, arrays and hashes as returned values
* Support for chars
* Experimental (unsafe) casting of pointers to integers and back

#### Breaking changes

* Rename `convert_arg` to `convert_regular_arg`
* Rename `convert_keyword_arg` to `convert_from_ruby_to_crystal`
* Rename `convert_resolved_arg` to `resolve_regular_arg`
* Rename `convert_resolved_keyword_arg` to `resolve_from_ruby_to_crystal`

#### Usability

* Better error messages when casting incompatible values
* Added dummy argument parsing to convert type calls into actual types
* More intelligent conversions (Char <-> String, Int -> Float, Symbol -> String)

#### Bugfixes

* Fixed reference table throwing an error when increasing counter
* Call rb_finalize only if reference counter is going to be 0
* Fixed union type parsing
* Removed possible error when casting unions

### Version 0.9.1

#### Usability

* Allow for a wrapped function to return nil by default

#### Bugfixes

* Fixed broken documentation

### Version 0.9.0

#### Features

* Additional compatibility layer between Anyolite and mruby
* More configuration options

#### Breaking changes

* Renamed `MrbWrap` to `Anyolite`
* Renamed `MrbMacro` to `Anyolite::Macro`
* Renamed `mrb` and `mruby` in the code to `rb` and `ruby`
* Reworked configurations for the Rakefile into a class
* Dropped support for mruby 2

#### Safety

* Warning message when a reference table with values is reset
* Added pedantic setting for reference table (default)
* More reliable internal checks for union arguments

#### Usability

* Split macro source file into smaller parts
* Update documentation to new code

#### Bugfixes

* Enums are now correctly tracked in the reference table

### Version 0.8.1

#### Usability

* Explicitly exclude pointers
* Explicitly exclude procs
* Added recompilation options for the Rakefile

#### Bugfixes

* Fixed exception for class methods with empty regular argument list
* Allow operator methods for class and module methods
* Fixed path resolution for types starting with `::`
* Resolve generics as arguments for generics properly
* Fix broken floats in mruby

### Version 0.8.0

#### Features

* Uses mruby 3.0.0 by default

#### Breaking changes

* Compatibility with mruby 2.1.2 requires additional flag

#### Usability

* Casting methods are more compatible between mruby versions

### Version 0.7.0

#### Features

* Support for wrapping generics using annotations
* Non-keyword arguments allow for union and generic type arguments
* Annotation for non-keyword arguments accepts number as optional argument

#### Breaking changes

* Non-keyword arguments need to be specialized explicitly
* More consistent wrapping of operator methods

#### Usability

* More helpful error messages when path resolution fails

#### Bugfixes

* Specialization to new arguments did not allow non-keyword annotations
* Correct wrapping of most aliased types
* Methods with non-letter-symbols could not be wrapped
* Default arguments with colons were wrongly assumed to be keywords
* Enabled support for regular string argument with default values
* Fixed incomplete resolution of paths

### Version 0.6.1

#### Bugfixes

* Non-public constructor methods could not be wrapped

### Version 0.6.0

#### Features

* Wrappers for unions
* Wrappers for nilable objects

#### Breaking changes

* Wrapping of specific functions has a more consistent syntax using Arrays instead of Hashes

#### Safety

* More useful compiletime errors for macros
* More information when encountering type casting errors
* Use Array(TypeDeclaration) instead of Hash for keywords in internal methods

#### Usability

* Cleaned up some code fragments

#### Bugfixes

* Wrapped struct objects were immutable

### Version 0.5.0

#### Features

* Support for enums
* Ability to rename classes and modules

#### Usability

* Empty argument list for specialization can be specified with nil
* Exclusion message for mruby methods, finalize and to_unsafe
* Exclusion of non-public methods
* Exclusion of to_unsafe
* Non-fatal runtime errors are triggered in mruby instead of Crystal

#### Bugfixes

* Proper resolution of class and module hierarchies

### Version 0.4.1

#### Usability

* Method names in annotations can be given as strings
* More and better verbose information for wrapping

#### Bugfixes

* Setters can be excluded correctly
* Manually wrapped properties work correctly now
* Correct handling of generic function arguments like Int, Number or Float

### Version 0.4.0

#### Features

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

#### Features

* Keyword argument support
* Support for optional keywords
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

#### Features

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