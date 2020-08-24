require "./MrbInternal.cr"

require "./MrbState.cr"
require "./MrbClass.cr"
require "./MrbCast.cr"
require "./MrbMacro.cr"
require "./MrbClassCache.cr"
require "./MrbTypeCache.cr"
require "./MrbModule.cr"
require "./MrbRefTable.cr"

alias MrbFunc = Proc(MrbInternal::MrbState*, MrbInternal::MrbValue, MrbInternal::MrbValue)

module MrbWrap
  struct Opt(T, D)
  end

  macro wrap_class(mrb_state, crystal_class, name, under = nil)
    new_class = MrbClass.new({{mrb_state}}, {{name}}, under: {{under}})
    MrbInternal.set_instance_tt_as_data(new_class)
    MrbClassCache.register({{crystal_class}}, new_class)
  end

  # TODO: Maybe use MrbModuleCache for this?
  macro wrap_module(mrb_state, crystal_module, name, under = nil)
    new_module = MrbModule.new({{mrb_state}}, {{name}}, under: {{under}})
    MrbClassCache.register({{crystal_module}}, new_module)
  end

  # TODO: Accept single arguments in non-Array-form as well
  macro wrap_constructor(mrb_state, crystal_class, proc_args = [] of Class)
    {% if proc_args.empty? %}
      MrbMacro.wrap_constructor_function({{mrb_state}}, {{crystal_class}}, ->{{crystal_class}}.new, {{proc_args}})
    {% else %}
      # The following construct is ugly, but Crystal forbids a newline there for some reason
      MrbMacro.wrap_constructor_function({{mrb_state}}, {{crystal_class}}, 
      ->{{crystal_class}}.new({% for arg in proc_args %} {% if arg.resolve <= Opt %} {{arg.type_vars[0]}}, {% else %} {{arg}}, {% end %} {% end %}), {{proc_args}})
    {% end %}
  end

  macro wrap_module_function(mrb_state, under_module, name, proc, proc_args = [] of Class)
    {% if proc_args.empty? %}
      MrbMacro.wrap_module_function_with_args({{mrb_state}}, {{under_module}}, {{name}}, ->{{proc}}, {{proc_args}})
    {% else %}
      MrbMacro.wrap_module_function_with_args({{mrb_state}}, {{under_module}}, {{name}}, 
      ->{{proc}}({% for arg in proc_args %} {% if arg.resolve <= Opt %} {{arg.type_vars[0]}}, {% else %} {{arg}}, {% end %} {% end %}), {{proc_args}})
    {% end %}
  end

  macro wrap_class_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class)
    {% if proc_args.empty? %}
      MrbMacro.wrap_class_method_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, ->{{proc}}, {{proc_args}})
    {% else %}
      MrbMacro.wrap_class_method_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, 
      ->{{proc}}({% for arg in proc_args %} {% if arg.resolve <= Opt %} {{arg.type_vars[0]}}, {% else %} {{arg}}, {% end %} {% end %}), {{proc_args}})
    {% end %}
  end

  macro wrap_instance_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, ->(
      obj : {{crystal_class}},

      {% c = 0 %}
      {% for arg in proc_args %}
        {% if arg.resolve <= Opt %}
          arg_{{c}} : {{arg.type_vars[0]}},
        {% else %}
          arg_{{c}} : {{arg}},
        {% end %}
        {% c += 1 %}
      {% end %}

    ) {obj.{{proc}}(
        
      {% c = 0 %}
      {% for arg in proc_args %}
        arg_{{c}},
        {% c += 1 %}
      {% end %}

    )}, [{{crystal_class}}, {{*proc_args}}])
  end

  macro wrap_setter(mrb_state, crystal_class, name, proc, proc_arg)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, ->(
      obj : {{crystal_class}},
      arg : {{proc_arg}}
    ) {obj.{{proc}} = arg}, [{{crystal_class}}, {{proc_arg}}])
  end

  macro wrap_getter(mrb_state, crystal_class, name, proc)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, ->(
      obj : {{crystal_class}}
    ) {obj.{{proc}}}, [{{crystal_class}}])
  end

  macro wrap_property(mrb_state, crystal_class, name, proc, proc_arg)
    MrbWrap.wrap_getter({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}})
    MrbWrap.wrap_setter({{mrb_state}}, {{crystal_class}}, {{name}} + "=", {{proc}}, {{proc_arg}})
  end

  macro wrap_constant(mrb_state, under_module, name, crystal_value)
    MrbInternal.mrb_define_const({{mrb_state}}, {{under_module}}, {{name}}, MrbCast.return_value({{mrb_state}}.to_unsafe, {{crystal_value}}))
  end
end
