module MrbMacro
  macro format_string(proc)
    {% format_str = "" %}

    {% for arg in proc.args %}
      {% if arg.resolve <= Bool %}
        {% format_str += "b" %}
      {% elsif arg.resolve <= Int %}
        {% format_str += "i" %}
      {% elsif arg.resolve <= Float %}
        {% format_str += "f" %}
      {% elsif arg.resolve <= String %}
        {% format_str += "z" %}
      {% else %}
        {% format_str += "o" %}
      {% end %}
    {% end %}

    {{format_str}}
  end

  # NOTE: May be obsolete
  macro type_in_ruby(type)
    {% if type.resolve <= Bool %}
      MrbInternal::MrbBool
    {% elsif type.resolve <= Int %}
      MrbInternal::MrbInt
    {% elsif type.resolve <= Float %}
      MrbInternal::MrbFloat
    {% elsif type.resolve <= String %}
      LibC::Char*
    {% else %}
      MrbInternal::MrbValue
    {% end %}
  end

  macro pointer_type(type)
    {% if type.resolve <= Bool %}
      Pointer(MrbInternal::MrbBool)
    {% elsif type.resolve <= Int %}
      Pointer(MrbInternal::MrbInt)
    {% elsif type.resolve <= Float %}
      Pointer(MrbInternal::MrbFloat)
    {% elsif type.resolve <= String %}
      Pointer(LibC::Char*)
    {% else %}
      Pointer(MrbInternal::MrbValue)
    {% end %}
  end

  macro generate_arg_tuple(proc)
    Tuple.new(
      {% for arg in proc.args %}
        MrbMacro.pointer_type({{arg}}).malloc(size: 1),
      {% end %}
    )
  end

  macro get_raw_args(mrb, proc)
    args = MrbMacro.generate_arg_tuple({{proc}})
    format_string = MrbMacro.format_string({{proc}})
    MrbInternal.mrb_get_args(mrb, format_string, *args)
    args
  end

  # Converts Ruby values to Crystal values
  macro convert_arg(mrb, arg, arg_type)
    {% if arg_type.resolve <= Bool %}
      ({{arg}} != 0)
    {% elsif arg_type.resolve <= Int %}
      {{arg_type}}.new({{arg}})
    {% elsif arg_type.resolve <= Float %}
      {{arg_type}}.new({{arg}})
    {% elsif arg_type.resolve <= String %}
      {{arg_type}}.new({{arg}})
    # TODO: Pointer as possible class
    {% else %}
      MrbMacro.convert_from_ruby_object({{mrb}}, {{arg}}, {{arg_type}}).value
    {% end %}
  end

  macro convert_from_ruby_object(mrb, obj, crystal_type)
    # TODO: Add type check
    ruby_type = MrbInternal.data_type({{obj}})
    ptr = MrbInternal.mrb_data_get_ptr({{mrb}}, {{obj}}, ruby_type)
    ptr.as({{crystal_type}}*)
  end

  macro init_ruby_object(mrb, obj, crystal_type, *args)
    crystal_object = {{crystal_type}}.new(*args)
    # TODO: Further stuff
  end

  macro call_and_return(mrb, proc, converted_args)
    return_value = {{proc}}.call(*{{converted_args}})
    MrbCast.return_value({{mrb}}, return_value)
  end

  macro get_converted_args(mrb, proc)
    args = MrbMacro.generate_arg_tuple({{proc}})
    format_string = MrbMacro.format_string({{proc}})
    MrbInternal.mrb_get_args(mrb, format_string, *args)

    Tuple.new(
      {% c = 0 %}
      {% for arg in proc.args %}
        MrbMacro.convert_arg(mrb, args[{{c}}].value, {{arg}}),
        {% c += 1 %}
      {% end %}
    )
  end

  macro wrap_function(mrb_state, crystal_class, name, proc)
    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc}})
      MrbMacro.call_and_return(mrb, {{proc}}, converted_args)
    end

    mrb.define_method({{name}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end 

  macro wrap_class(mrb, crystal_class, name)
    new_class = MrbClass.new({{mrb}}, {{name}})
    MrbInternal.set_instance_tt_as_data(new_class)
    MrbClassCache.register({{crystal_class}}, new_class)
  end
end
