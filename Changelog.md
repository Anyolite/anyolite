# Changelog

## Releases

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