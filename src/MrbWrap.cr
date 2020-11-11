require "./MrbInternal.cr"

require "./MrbState.cr"
require "./MrbClass.cr"
require "./MrbCast.cr"
require "./MrbMacro.cr"
require "./MrbClassCache.cr"
require "./MrbModuleCache.cr"
require "./MrbTypeCache.cr"
require "./MrbModule.cr"
require "./MrbRefTable.cr"

# Alias for the mruby function pointers
alias MrbFunc = Proc(MrbInternal::MrbState*, MrbInternal::MrbValue, MrbInternal::MrbValue)

# Main wrapper module, which should be covering most of the use cases
module MrbWrap

  # Alias for all possible mruby return types
  alias Interpreted = Nil | Bool | MrbInternal::MrbFloat | MrbInternal::MrbInt | String | Undefined

  # Special struct representing undefined values in mruby
  struct Undefined
    # :nodoc:
    def initialize
    end
  end

  # Use this special constant in case of a function to wrap, which has only an operator as a name
  struct Empty
  end

  class StructWrapper(T)
    @content : T | Nil = nil

    def initialize(value)
      @content = value
    end

    def content : T
      if c = @content 
        c
      else
        raise("Content undefined!")
      end
    end

    def content=(value)
      @content = value
    end
  end

  # Undefined mruby value
  Undef = Undefined.new

  # Wraps a Crystal class directly into an mruby class.
  # 
  # The Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with *name* as its new designation, returning an `MrbClass`.
  # 
  # To inherit from another mruby class, specify an `MrbClass` as a *superclass*.
  #
  # Each class can be defined in a specifiy module by setting *under* to a `MrbModule`.
  macro wrap_class(mrb_state, crystal_class, name, under = nil, superclass = nil)
    new_class = MrbClass.new({{mrb_state}}, {{name}}, under: MrbModuleCache.get({{under}}), superclass: MrbClassCache.get({{superclass}}))
    MrbInternal.set_instance_tt_as_data(new_class)
    MrbClassCache.register({{crystal_class}}, new_class)
    MrbClassCache.get({{crystal_class}})
  end

  # Wraps a Crystal module into an mruby module.
  # 
  # The module *crystal_module* will be integrated into the `MrbState` *mrb_state*,
  # with *name* as its new designation, returning an `MrbModule`.
  # 
  # The parent module can be specified with the module argument *under*.
  macro wrap_module(mrb_state, crystal_module, name, under = nil)
    new_module = MrbModule.new({{mrb_state}}, {{name}}, under: MrbModuleCache.get({{under}}))
    MrbModuleCache.register({{crystal_module}}, new_module)
    MrbModuleCache.get({{crystal_module}})
  end

  # Wraps the constructor of a Crystal class into mruby.
  # 
  # The constructor for the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  macro wrap_constructor(mrb_state, crystal_class, proc_args = [] of Class, operator = "", context = nil)
    MrbMacro.wrap_constructor_function_with_args({{mrb_state}}, {{crystal_class}}, {{crystal_class}}.new, {{proc_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps the constructor of a Crystal class into mruby, using keyword arguments.
  # 
  # The constructor for the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as a `Hash of Symbol => Class`.
  # Alternatively, a `Tuple` with the `Class` and a default value for the `Class` can be used instead of the `Class`.
  macro wrap_constructor_with_keywords(mrb_state, crystal_class, keyword_args, regular_args = [] of Class, operator = "", context = nil)
    MrbMacro.wrap_constructor_function_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{crystal_class}}.new, {{keyword_args}}, {{regular_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a module function into mruby.
  # 
  # The function *proc* under the module *under_module* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_module_function(mrb_state, under_module, name, proc, proc_args = [] of Class, operator = "", context = nil)
    MrbMacro.wrap_module_function_with_args({{mrb_state}}, {{under_module}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a module function into mruby, using keyword arguments.
  # 
  # The function *proc* under the module *under_module* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as a `Hash of Symbol => Class`.
  # Alternatively, a `Tuple` with the `Class` and a default value for the `Class` can be used instead of the `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_module_function_with_keywords(mrb_state, under_module, name, proc, keyword_args, regular_args = [] of Class, operator = "", context = nil)
    MrbMacro.wrap_module_function_with_keyword_args({{mrb_state}}, {{under_module}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a class method into mruby.
  # 
  # The class method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_class_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class, operator = "", context = nil)
    MrbMacro.wrap_class_method_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a class method into mruby, using keyword arguments.
  # 
  # The class method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as a `Hash of Symbol => Class`.
  # Alternatively, a `Tuple` with the `Class` and a default value for the `Class` can be used instead of the `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_class_method_with_keywords(mrb_state, crystal_class, name, proc, keyword_args, regular_args = [] of Class, operator = "", context = nil)
    MrbMacro.wrap_class_method_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps an instance method into mruby.
  # 
  # The instance method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_instance_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class, operator = "", context = nil)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}}, context: {{context}})
  end
  
  # Wraps an instance method into mruby, using keyword arguments.
  # 
  # The instance method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as a `Hash of Symbol => Class`.
  # Alternatively, a `Tuple` with the `Class` and a default value for the `Class` can be used instead of the `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_instance_method_with_keywords(mrb_state, crystal_class, name, proc, keyword_args, regular_args = [] of Class, operator = "", context = nil)
    MrbMacro.wrap_instance_function_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a setter into mruby.  
  # 
  # The setter *proc* (without the `=`) of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the argument *proc_arg* as its respective `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_setter(mrb_state, crystal_class, name, proc, proc_arg, operator = "=", context = nil)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_arg}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a getter into mruby.  
  # 
  # The getter *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*.
  # 
  # Its new name will be *name*.
  macro wrap_getter(mrb_state, crystal_class, name, proc, operator = "", context = nil)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, operator: {{operator}}, context: {{context}})
  end

  # Wraps a property into mruby.  
  # 
  # The property *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the argument *proc_arg* as its respective `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_property(mrb_state, crystal_class, name, proc, proc_arg, operator_getter = "", operator_setter = "=", context = nil)
    MrbWrap.wrap_getter({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, operator: {{operator_getter}}, context: {{context}})
    MrbWrap.wrap_setter({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_arg}}, operator: {{operator_setter}}, context: {{context}})
  end

  # Wraps a constant value under a module into mruby.
  # 
  # The value *crystal_value* will be integrated into the `MrbState` *mrb_state*,
  # with the name *name* and the parent module *under_module*.
  macro wrap_constant(mrb_state, under_module, name, crystal_value)
    MrbInternal.mrb_define_const({{mrb_state}}, MrbModuleCache.get({{under_module}}), {{name}}, MrbCast.return_value({{mrb_state}}.to_unsafe, {{crystal_value}}))
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

  annotation Exclude; end
  annotation ExcludeInstanceMethod; end
  annotation ExcludeClassMethod; end
  annotation ExcludeConstant; end

  annotation Specialize; end
  annotation SpecializeInstanceMethod; end
  annotation SpecializeClassMethod; end

  annotation Rename; end
  annotation RenameInstanceMethod; end
  annotation RenameClassMethod; end
  annotation RenameConstant; end

  annotation WrapWithoutKeywords; end
  annotation WrapWithoutKeywordsInstanceMethod; end
  annotation WrapWithoutKeywordsClassMethod; end

  macro wrap_class_with_methods(mrb_state, crystal_class, under = nil, 
    instance_method_exclusions = [] of String | Symbol, 
    class_method_exclusions = [] of String | Symbol, 
    constant_exclusions = [] of String | Symbol,
    verbose = false)
    
    # Things left to do:
    # - Wrap modules similarly to classes
    # - Wrap modules and all their classes and constants
    # - Wrap stuff from inherited classes if wanted
    # - Display warning if a function gets wrapped more than once
    # - Display function args for repeated wrapping (replaced ones and new ones?)
    # - Maybe improve context::class resolution by splitting context into its components?
    # - Test, test and test

    MrbWrap.wrap_class({{mrb_state}}, {{crystal_class.resolve}}, "{{crystal_class.names.last}}", under: {{under}})

    MrbMacro.wrap_all_instance_methods({{mrb_state}}, {{crystal_class}}, {{instance_method_exclusions}}, {{verbose}}, context: {{under}})
    MrbMacro.wrap_all_class_methods({{mrb_state}}, {{crystal_class}}, {{class_method_exclusions}}, {{verbose}}, context: {{under}})
    MrbMacro.wrap_all_constants({{mrb_state}}, {{crystal_class}}, {{constant_exclusions}}, {{verbose}})
  end

  macro wrap_module_with_methods(mrb_state, crystal_module, under = nil,
    class_method_exclusions = [] of String | Symbol,
    constant_exclusions = [] of String | Symbol,
    verbose = false)

    MrbWrap.wrap_module({{mrb_state}}, {{crystal_module.resolve}}, "{{crystal_module}}", under: {{under}})
    MrbMacro.wrap_all_class_methods({{mrb_state}}, {{crystal_module}}, {{class_method_exclusions}}, {{verbose}}, context: {{under}})
    MrbMacro.wrap_all_constants({{mrb_state}}, {{crystal_module}}, {{constant_exclusions}}, {{verbose}})
  end
end
