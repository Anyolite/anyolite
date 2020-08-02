require "./MrbInternal.cr"

require "./MrbState.cr"
require "./MrbClass.cr"
require "./MrbCast.cr"
require "./MrbMacro.cr"
require "./MrbClassCache.cr"

alias MrbFunc = Proc(MrbInternal::MrbState*, MrbInternal::MrbValue, MrbInternal::MrbValue)

module MrbWrap
  macro wrap_class(mrb_state, crystal_class, name)
    new_class = MrbClass.new({{mrb_state}}, {{name}})
    MrbInternal.set_instance_tt_as_data(new_class)
    MrbClassCache.register({{crystal_class}}, new_class)
  end

  # TODO: Accept single arguments in non-Array-form as well
  macro wrap_constructor(mrb_state, crystal_class, proc_args = [] of Class)
    MrbMacro.wrap_constructor_function({{mrb_state}}, {{crystal_class}}, ->{{crystal_class}}.new({{*proc_args}}))
  end

  macro wrap_instance_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class)
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, ->(
      obj : {{crystal_class}},

      {% c = 0 %}
      {% for arg in proc_args %}
        arg_{{c}} : {{arg}},
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
end
