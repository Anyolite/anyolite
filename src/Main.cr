require "./MrbInternal.cr"

require "./RbInterpreter.cr"
require "./RbClass.cr"
require "./MrbCast.cr"
require "./MrbMacro.cr"
require "./MrbClassCache.cr"
require "./MrbTypeCache.cr"
require "./RbModule.cr"
require "./MrbRefTable.cr"

# Alias for the mruby function pointers.
alias MrbFunc = Proc(MrbInternal::MrbState*, MrbInternal::MrbValue, MrbInternal::MrbValue)

# Main wrapper module, which should be covering most of the use cases.
module Anyolite
  # Alias for all possible mruby return types.
  alias Interpreted = Nil | Bool | MrbInternal::MrbFloat | MrbInternal::MrbInt | String | Undefined

  # Special struct representing undefined values in mruby.
  struct Undefined
    # :nodoc:
    def initialize
    end
  end

  # Use this special constant in case of a function to wrap, which has only an operator as a name.
  struct Empty
    # :nodoc:
    def initialize
    end
  end

  # Internal class to hide the `Struct` *T* in a special class
  # to obtain all class-related properties.
  class StructWrapper(T)
    @content : T | Nil = nil

    def initialize(value)
      @content = value
    end

    def content : T
      if c = @content
        c
      else
        # This should not be called theoretically
        raise("Content of struct wrapper is undefined!")
      end
    end

    def content=(value)
      @content = value
    end
  end

  # Undefined mruby value.
  Undef = Undefined.new

  # Wraps a Crystal class directly into an mruby class.
  #
  # The Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with *name* as its new designation, returning an `Anyolite::RbClass`.
  #
  # To inherit from another mruby class, specify an `Anyolite::RbClass` as a *superclass*.
  #
  # Each class can be defined in a specifiy module by setting *under* to a `Anyolite::RbModule`.
  macro wrap_class(mrb_state, crystal_class, name, under = nil, superclass = nil)
    new_class = Anyolite::RbClass.new({{mrb_state}}, {{name}}, under: MrbClassCache.get({{under}}), superclass: MrbClassCache.get({{superclass}}))
    MrbInternal.set_instance_tt_as_data(new_class)
    MrbClassCache.register({{crystal_class}}, new_class)
    MrbClassCache.get({{crystal_class}})
  end

  # Wraps a Crystal module into an mruby module.
  #
  # The module *crystal_module* will be integrated into the `MrbState` *mrb_state*,
  # with *name* as its new designation, returning an `Anyolite::RbModule`.
  #
  # The parent module can be specified with the module argument *under*.
  macro wrap_module(mrb_state, crystal_module, name, under = nil)
    new_module = Anyolite::RbModule.new({{mrb_state}}, {{name}}, under: MrbClassCache.get({{under}}))
    MrbClassCache.register({{crystal_module}}, new_module)
    MrbClassCache.get({{crystal_module}})
  end

  # Wraps the constructor of a Crystal class into mruby.
  #
  # The constructor for the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`. 
  # 
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_constructor(mrb_state, crystal_class, proc_args = nil, operator = "", context = nil)
    MrbMacro.wrap_constructor_function_with_args({{mrb_state}}, {{crystal_class}}, {{crystal_class}}.new, {{proc_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps the constructor of a Crystal class into mruby, using keyword arguments.
  #
  # The constructor for the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as an `Array of TypeDeclaration`.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_constructor_with_keywords(mrb_state, crystal_class, keyword_args, regular_args = nil, operator = "", context = nil)
    MrbMacro.wrap_constructor_function_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{crystal_class}}.new, {{keyword_args}}, {{regular_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a module function into mruby.
  #
  # The function *proc* under the module *under_module* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  #
  # Its new name will be *name*.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_module_function(mrb_state, under_module, name, proc, proc_args = nil, operator = "", context = nil)
    MrbMacro.wrap_module_function_with_args({{mrb_state}}, {{under_module}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a module function into mruby, using keyword arguments.
  #
  # The function *proc* under the module *under_module* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as an `Array of TypeDeclaration`.
  #
  # Its new name will be *name*.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_module_function_with_keywords(mrb_state, under_module, name, proc, keyword_args, regular_args = nil, operator = "", context = nil)
    MrbMacro.wrap_module_function_with_keyword_args({{mrb_state}}, {{under_module}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a class method into mruby.
  #
  # The class method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  #
  # Its new name will be *name*.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_class_method(mrb_state, crystal_class, name, proc, proc_args = nil, operator = "", context = nil)
    MrbMacro.wrap_class_method_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a class method into mruby, using keyword arguments.
  #
  # The class method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as an `Array of TypeDeclaration`.
  #
  # Its new name will be *name*.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_class_method_with_keywords(mrb_state, crystal_class, name, proc, keyword_args, regular_args = nil, operator = "", context = nil)
    MrbMacro.wrap_class_method_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps an instance method into mruby.
  #
  # The instance method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  #
  # Its new name will be *name*.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_instance_method(mrb_state, crystal_class, name, proc, proc_args = nil, operator = "", context = nil)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps an instance method into mruby, using keyword arguments.
  #
  # The instance method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as an `Array of TypeDeclaration`.
  #
  # Its new name will be *name*.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_instance_method_with_keywords(mrb_state, crystal_class, name, proc, keyword_args, regular_args = nil, operator = "", context = nil)
    MrbMacro.wrap_instance_function_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a setter into mruby.
  #
  # The setter *proc* (without the `=`) of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the argument *proc_arg* as its respective `Class`.
  #
  # Its new name will be *name*.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_setter(mrb_state, crystal_class, name, proc, proc_arg, operator = "=", context = nil)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_arg}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a getter into mruby.
  #
  # The getter *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*.
  #
  # Its new name will be *name*.
  #
  # The value *operator* will append the specified `String`
  # to the final name and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_getter(mrb_state, crystal_class, name, proc, operator = "", context = nil)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a property into mruby.
  #
  # The property *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the argument *proc_arg* as its respective `Class`.
  #
  # Its new name will be *name*.
  #
  # The values *operator_getter* and *operator_setter* will append the specified `String`
  # to the final names and *context* can give the function a `Path` for resolving types correctly.
  macro wrap_property(mrb_state, crystal_class, name, proc, proc_arg, operator_getter = "", operator_setter = "=", context = nil)
    Anyolite.wrap_getter({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, operator: {{operator_getter}}, context: {{context}})
    Anyolite.wrap_setter({{mrb_state}}, {{crystal_class}}, {{name + "="}}, {{proc}}, {{proc_arg}}, operator: {{operator_setter}}, context: {{context}})
  end

  # Wraps a constant value under a module into mruby.
  #
  # The value *crystal_value* will be integrated into the `MrbState` *mrb_state*,
  # with the name *name* and the parent module *under_module*.
  macro wrap_constant(mrb_state, under_module, name, crystal_value)
    MrbInternal.mrb_define_const({{mrb_state}}, MrbClassCache.get({{under_module}}), {{name}}, MrbCast.return_value({{mrb_state}}.to_unsafe, {{crystal_value}}))
  end

  # Wraps a constant value under a class into mruby.
  #
  # The value *crystal_value* will be integrated into the `MrbState` *mrb_state*,
  # with the name *name* and the parent `Class` *under_class*.
  macro wrap_constant_under_class(mrb_state, under_class, name, crystal_value)
    MrbInternal.mrb_define_const({{mrb_state}}, MrbClassCache.get({{under_class}}), {{name}}, MrbCast.return_value({{mrb_state}}.to_unsafe, {{crystal_value}}))
  end

  # NOTE: Annotations like SpecializeConstant are not defined for obvious reasons
  # TODO: Annotations for constants are currently not obtainable with macros (?)

  # Excludes the function from wrapping.
  annotation Exclude; end

  # Excludes the instance method given as the first argument from wrapping.
  annotation ExcludeInstanceMethod; end

  # Excludes the class method given as the first argument from wrapping.
  annotation ExcludeClassMethod; end

  # Excludes the constant given as the first argument from wrapping.
  annotation ExcludeConstant; end

  # Excludes all definitions of this function besides this one from wrapping.
  # The optional first argument overwrites the original argument array.
  annotation Specialize; end

  # Excludes all definitions of the instance method given as the first argument 
  # besides the one with the arguments given in the second argument (`nil` for none) from wrapping.
  # The optional third argument overwrites the original argument array.
  annotation SpecializeInstanceMethod; end

  # Excludes all definitions of the class method given as the first argument 
  # besides the one with the arguments given in the second argument (`nil` for none) from wrapping.
  # The optional third argument overwrites the original argument array.
  annotation SpecializeClassMethod; end

  # Renames the function to the first argument if wrapped.
  annotation Rename; end

  # Renames the instane method given as the first argument
  # to the second argument if wrapped.
  annotation RenameInstanceMethod; end

  # Renames the class method given as the first argument
  # to the second argument if wrapped.
  annotation RenameClassMethod; end

  # Renames the constant given as the first argument
  # to the second argument if wrapped.
  annotation RenameConstant; end

  # Renames the class to the first argument if wrapped.
  annotation RenameClass; end

  # Renames the module to the first argument if wrapped.
  annotation RenameModule; end

  # Wraps all arguments of the function to positional arguments.
  # The optional argument limits the number of arguments to wrap as positional
  # arguments (`-1` for all arguments).
  annotation WrapWithoutKeywords; end

  # Wraps all arguments of the instance method given as the first argument
  # to positional arguments.
  # The optional seconds argument limits the number of arguments to wrap as positional
  # arguments (`-1` for all arguments).
  annotation WrapWithoutKeywordsInstanceMethod; end

  # Wraps all arguments of the class method given as the first argument
  # to positional arguments.
  # The optional seconds argument limits the number of arguments to wrap as positional
  # arguments (`-1` for all arguments).
  annotation WrapWithoutKeywordsClassMethod; end

  # Specifies the generic type names for the following class as its argument,
  # in form of an `Array` of their names.
  annotation SpecifyGenericTypes; end

  # Wraps a whole class structure under a module into mruby.
  #
  # The `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the optional parent module *under*.
  # Methods or constants to be excluded can be specified as 
  # `Symbol` or `String` in the `Array` 
  # *instance_method_exclusions* (for instance methods),
  # *class_method_exclusions* (for class methods) or 
  # *constant_exclusions* (for constants).
  # Enum classes can be wrapped by setting *use_enum_constructor*.
  # If *verbose* is set, wrapping information will be displayed.
  macro wrap_class_with_methods(mrb_state, crystal_class, under = nil,
                                instance_method_exclusions = [] of String | Symbol,
                                class_method_exclusions = [] of String | Symbol,
                                constant_exclusions = [] of String | Symbol,
                                use_enum_constructor = false,
                                verbose = false)

    {% if verbose %}
      {% puts ">>> Going into class #{crystal_class} under #{under}\n\n" %}
    {% end %}

    {% if crystal_class.is_a?(Generic) %}
      {% puts "> Wrapping of generics not supported, thus skipping #{crystal_class}\e[0m\n\n" if verbose %}
    {% else %}
      {% resolved_class = crystal_class.resolve %}

      {% new_context = crystal_class %}

      {% if resolved_class.annotation(Anyolite::RenameClass) %}
        {% actual_name = resolved_class.annotation(Anyolite::RenameClass)[0] %}
      {% else %}
        {% actual_name = crystal_class.names.last.stringify %}
      {% end %}

      Anyolite.wrap_class({{mrb_state}}, {{resolved_class}}, {{actual_name}}, under: {{under}})

      MrbMacro.wrap_all_instance_methods({{mrb_state}}, {{crystal_class}}, {{instance_method_exclusions}}, 
        {{verbose}}, context: {{new_context}}, use_enum_constructor: {{use_enum_constructor}})
      MrbMacro.wrap_all_class_methods({{mrb_state}}, {{crystal_class}}, {{class_method_exclusions}}, {{verbose}}, context: {{new_context}})
      MrbMacro.wrap_all_constants({{mrb_state}}, {{crystal_class}}, {{constant_exclusions}}, {{verbose}}, context: {{new_context}})
    {% end %}
  end

  # Wraps a whole module structure under a module into mruby.
  #
  # The module *crystal_module* will be integrated into the `MrbState` *mrb_state*,
  # with the optional parent module *under*.
  # Methods or constants to be excluded can be specified as 
  # `Symbol` or `String` in the `Array` 
  # *class_method_exclusions* (for class methods) or 
  # *constant_exclusions* (for constants).
  # If *verbose* is set, wrapping information will be displayed.
  macro wrap_module_with_methods(mrb_state, crystal_module, under = nil,
                                 class_method_exclusions = [] of String | Symbol,
                                 constant_exclusions = [] of String | Symbol,
                                 verbose = false)

    {% if verbose %}
      {% puts ">>> Going into module #{crystal_module} under #{under}\n\n" %}
    {% end %}

    {% new_context = crystal_module %}

    {% if crystal_module.resolve.annotation(Anyolite::RenameModule) %}
      {% actual_name = crystal_module.resolve.annotation(Anyolite::RenameModule)[0] %}
    {% else %}
      {% actual_name = crystal_module.names.last.stringify %}
    {% end %}

    Anyolite.wrap_module({{mrb_state}}, {{crystal_module.resolve}}, {{actual_name}}, under: {{under}})

    MrbMacro.wrap_all_class_methods({{mrb_state}}, {{crystal_module}}, {{class_method_exclusions}}, {{verbose}}, context: {{new_context}})
    MrbMacro.wrap_all_constants({{mrb_state}}, {{crystal_module}}, {{constant_exclusions}}, {{verbose}}, context: {{new_context}})
  end

  # Wraps a whole class or module structure under a module into mruby.
  #
  # The class or module *crystal_module_or_class* will be integrated 
  # into the `MrbState` *mrb_state*,
  # with the optional parent module *under*.
  # Methods or constants to be excluded can be specified as 
  # `Symbol` or `String` in the `Array` 
  # *class_method_exclusions* (for class methods) or 
  # *constant_exclusions* (for constants).
  # If *verbose* is set, wrapping information will be displayed. 
  macro wrap(mrb_state, crystal_module_or_class, under = nil,
             instance_method_exclusions = [] of String | Symbol,
             class_method_exclusions = [] of String | Symbol,
             constant_exclusions = [] of String | Symbol,
             verbose = false)
    
    {% if !crystal_module_or_class.is_a?(Path) %}
      {% puts "\e[31m> WARNING: Object #{crystal_module_or_class} of #{crystal_module_or_class.class_name.id} is neither a class nor module, so it will be skipped\e[0m" %}
    {% elsif crystal_module_or_class.resolve.module? %}
      Anyolite.wrap_module_with_methods({{mrb_state}}, {{crystal_module_or_class}}, under: {{under}},
        class_method_exclusions: {{class_method_exclusions}},
        constant_exclusions: {{constant_exclusions}},
        verbose: {{verbose}}
      )
    {% elsif crystal_module_or_class.resolve.class? || crystal_module_or_class.resolve.struct? %}
      Anyolite.wrap_class_with_methods({{mrb_state}}, {{crystal_module_or_class}}, under: {{under}},
        instance_method_exclusions: {{instance_method_exclusions}},
        class_method_exclusions: {{class_method_exclusions}},
        constant_exclusions: {{constant_exclusions}},
        verbose: {{verbose}}
      )
    {% elsif crystal_module_or_class.resolve.union? %}
      {% puts "\e[31m> WARNING: Wrapping of unions not supported, thus skipping #{crystal_module_or_class}\e[0m" %}
    {% elsif crystal_module_or_class.resolve < Enum %}
      Anyolite.wrap_class_with_methods({{mrb_state}}, {{crystal_module_or_class}}, under: {{under}},
        instance_method_exclusions: {{instance_method_exclusions}},
        class_method_exclusions: {{class_method_exclusions}},
        constant_exclusions: {{constant_exclusions}},
        use_enum_constructor: true,
        verbose: {{verbose}}
      )
    {% elsif crystal_module_or_class.resolve.is_a?(TypeNode) %}
      Anyolite.wrap_class_with_methods({{mrb_state}}, {{crystal_module_or_class}}, under: {{under}},
        instance_method_exclusions: {{instance_method_exclusions}},
        class_method_exclusions: {{class_method_exclusions}},
        constant_exclusions: {{constant_exclusions}},
        verbose: {{verbose}}
      )
    {% else %}
      {% puts "\e[31m> WARNING: Could not resolve #{crystal_module_or_class}, so it will be skipped\e[0m" %}
    {% end %}
  end
end
