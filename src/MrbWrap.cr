require "./MrbInternal.cr"

require "./MrbState.cr"
require "./MrbClass.cr"
require "./MrbCast.cr"
require "./MrbMacro.cr"
require "./MrbClassCache.cr"
require "./MrbTypeCache.cr"
require "./MrbModule.cr"
require "./MrbRefTable.cr"

# Alias for the mruby function pointers
alias MrbFunc = Proc(MrbInternal::MrbState*, MrbInternal::MrbValue, MrbInternal::MrbValue)

# Main wrapper module, which should be covering most of the use cases
module MrbWrap

  # Alias for all possible mruby return types
  alias Interpreted = Nil | Bool | MrbInternal::MrbFloat | MrbInternal::MrbInt | String | Undefined

  # Helper structure which can be used to specify an optional argument of class *T* with default value *D*.
  #
  # No instances of this struct are necessary.
  struct Opt(T, D)
    # :nodoc:
    def initialize
    end
  end

  # Special struct representing undefined values in mruby
  struct Undefined
    # :nodoc:
    def initialize
    end
  end

  # Undefined mruby value
  Undef = Undefined.new

  # Wraps a Crystal class directly into an mruby class.
  # 
  # The Crystal class *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with *name* as its new designation, returning an `MrbClass`.
  # 
  # To inherit from another mruby class, specify an `MrbClass` as a *superclass*.
  #
  # Each class can be defined in a specifiy module by setting *under* to a `MrbModule`.
  macro wrap_class(mrb_state, crystal_class, name, under = nil, superclass = nil)
    new_class = MrbClass.new({{mrb_state}}, {{name}}, under: {{under}}, superclass: {{superclass}})
    MrbInternal.set_instance_tt_as_data(new_class)
    MrbClassCache.register({{crystal_class}}, new_class)
    MrbClassCache.get({{crystal_class}})
  end

  # Wraps a Crystal module into an mruby module.
  # 
  # The module *crystal_module* will be integrated into the `MrbState` *mrb_state*,
  # with *name* as its new designation, returning an `MrbModule`.
  # 
  # The parent module can be specified with the `MrbModule` argument *under*.
  macro wrap_module(mrb_state, crystal_module, name, under = nil)
    new_module = MrbModule.new({{mrb_state}}, {{name}}, under: {{under}})
    MrbClassCache.register({{crystal_module}}, new_module)
    MrbClassCache.get({{crystal_module}})
  end

  # Wraps the constructor of a Crystal class into mruby.
  # 
  # The constructor for the Crystal class *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  macro wrap_constructor(mrb_state, crystal_class, proc_args = [] of Class)
    {% if proc_args.empty? %}
      MrbMacro.wrap_constructor_function({{mrb_state}}, {{crystal_class}}, ->{{crystal_class}}.new, {{proc_args}})
    {% else %}
      # The following construct is ugly, but Crystal forbids a newline there for some reason
      MrbMacro.wrap_constructor_function({{mrb_state}}, {{crystal_class}}, 
      ->{{crystal_class}}.new({% for arg in proc_args %} {% if arg.resolve <= Opt %} {{arg.type_vars[0]}}, {% else %} {{arg}}, {% end %} {% end %}), {{proc_args}})
    {% end %}
  end

  # Wraps a module function into mruby.
  # 
  # The function *proc* under the `MrbModule` *under_module* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_module_function(mrb_state, under_module, name, proc, proc_args = [] of Class)
    {% if proc_args.empty? %}
      MrbMacro.wrap_module_function_with_args({{mrb_state}}, {{under_module}}, {{name}}, ->{{proc}}, {{proc_args}})
    {% else %}
      MrbMacro.wrap_module_function_with_args({{mrb_state}}, {{under_module}}, {{name}}, 
      ->{{proc}}({% for arg in proc_args %} {% if arg.resolve <= Opt %} {{arg.type_vars[0]}}, {% else %} {{arg}}, {% end %} {% end %}), {{proc_args}})
    {% end %}
  end

  # Wraps a class method into mruby.
  # 
  # The class method *proc* of the Crystal class *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_class_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class)
    {% if proc_args.empty? %}
      MrbMacro.wrap_class_method_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, ->{{proc}}, {{proc_args}})
    {% else %}
      MrbMacro.wrap_class_method_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, 
      ->{{proc}}({% for arg in proc_args %} {% if arg.resolve <= Opt %} {{arg.type_vars[0]}}, {% else %} {{arg}}, {% end %} {% end %}), {{proc_args}})
    {% end %}
  end

  # Wraps an instance method into mruby.
  # 
  # The instance method *proc* of the Crystal class *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_instance_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_args}})
  end
  
  # :nodoc:
  macro wrap_instance_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class, use_splat_args = false, keyword_args = {} of Symbol => Tuple(Class, Object), use_double_splat_args = false)
    # TODO: Macro body
    # TODO: Decide whether to use Tuple(Class, Object) or Tuple(Class) for the keyword argument types
    # TODO: Is it possible to use something like Class | Tuple(Class, Object) ?
  end

  # Wraps a setter into mruby.  
  # 
  # The setter *proc* (without the `=`) of the Crystal class *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the argument *proc_arg* as its respective `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_setter(mrb_state, crystal_class, name, proc, proc_arg)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_arg}}, "=")
  end

  # Wraps a getter into mruby.  
  # 
  # The getter *proc* of the Crystal class *crystal_class* will be integrated into the `MrbState` *mrb_state*.
  # 
  # Its new name will be *name*.
  macro wrap_getter(mrb_state, crystal_class, name, proc)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}})
  end

  # Wraps a property into mruby.  
  # 
  # The property *proc* of the Crystal class *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the argument *proc_arg* as its respective `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_property(mrb_state, crystal_class, name, proc, proc_arg)
    MrbWrap.wrap_getter({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}})
    MrbWrap.wrap_setter({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_arg}})
  end

  # Wraps a constant value into mruby.
  # 
  # The value *crystal_value* will be integrated into the `MrbState` *mrb_state*,
  # with the name *name* and the parent `MrbModule` *under_module*.
  macro wrap_constant(mrb_state, under_module, name, crystal_value)
    MrbInternal.mrb_define_const({{mrb_state}}, {{under_module}}, {{name}}, MrbCast.return_value({{mrb_state}}.to_unsafe, {{crystal_value}}))
  end
end
