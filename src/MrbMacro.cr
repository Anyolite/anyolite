# Helper methods which should not be used for trivial cases in the final version
module MrbMacro
  macro format_string(args)
    "" +
    {% for arg in args %}
      MrbMacro.format_char({{arg}}) +
    {% end %}
    ""
  end

  macro format_char(arg, optional_values = false)
    {% if arg.class_name == "TupleLiteral" %}
      puts "TUPLE: #{{{arg}}}"
      "|" + MrbMacro.format_char({{arg[0]}}, optional_values: true)
    {% elsif arg.resolve <= Bool %}
      "b"
    {% elsif arg.resolve <= Int %}
      "i"
    {% elsif arg.resolve <= Float %}
      "f"
    {% elsif arg.resolve <= String %}
      "z"
    {% elsif arg.resolve <= MrbWrap::Opt %}
      {% if optional_values != true %}
        "|" + MrbMacro.format_char({{arg.type_vars[0]}}, optional_values: true)
      {% else %}
        MrbMacro.format_char({{arg.type_vars[0]}}, optional_values: true)
      {% end %}
    {% else %}
      "o"
    {% end %}
  end

  macro type_in_ruby(type)
    {% if type.class_name == "TupleLiteral" %}
      MrbMacro.type_in_ruby({{type[0]}})
    {% elsif type.resolve <= Bool %}
      MrbInternal::MrbBool
    {% elsif type.resolve <= Int %}
      MrbInternal::MrbInt
    {% elsif type.resolve <= Float %}
      MrbInternal::MrbFloat
    {% elsif type.resolve <= String %}
      LibC::Char*
    {% elsif type.resolve <= MrbWrap::Opt %}
      MrbMacro.type_in_ruby({{type.type_vars[0]}})
    {% else %}
      MrbInternal::MrbValue
    {% end %}
  end

  macro pointer_type(type)
    {% if type.class_name == "TupleLiteral" %}
      MrbMacro.pointer_type({{type[0]}})
    {% elsif type.resolve <= Bool %}
      Pointer(MrbInternal::MrbBool)
    {% elsif type.resolve <= Int %}
      Pointer(MrbInternal::MrbInt)
    {% elsif type.resolve <= Float %}
      Pointer(MrbInternal::MrbFloat)
    {% elsif type.resolve <= String %}
      Pointer(LibC::Char*)
    {% elsif type.resolve <= MrbWrap::Opt %}
      MrbMacro.pointer_type({{type.type_vars[0]}})
    {% else %}
      Pointer(MrbInternal::MrbValue)
    {% end %}
  end

  macro generate_arg_tuple(args)
    Tuple.new(
      {% for arg in args %}
        {% if arg.class_name == "TupleLiteral" %}
          MrbMacro.pointer_type({{arg}}).malloc(size: 1, value: MrbMacro.type_in_ruby({{arg}}).new({{arg[1]}})),
        {% elsif arg.resolve <= MrbWrap::Opt %}
          MrbMacro.pointer_type({{arg}}).malloc(size: 1, value: MrbMacro.type_in_ruby({{arg}}).new({{arg.type_vars[1]}})),
        {% else %}
          MrbMacro.pointer_type({{arg}}).malloc(size: 1),
        {% end %}
      {% end %}
    )
  end

  macro get_raw_args(mrb, proc_args)
    args = MrbMacro.generate_arg_tuple({{proc_args}})
    format_string = MrbMacro.format_string({{proc_args}})
    MrbInternal.mrb_get_args({{mrb}}, format_string, *args)
    args
  end

  # Converts Ruby values to Crystal values
  macro convert_arg(mrb, arg, arg_type)
    {% if arg_type.class_name == "TupleLiteral" %}
      MrbMacro.convert_arg({{mrb}}, {{arg}}, {{arg_type[0]}})
    {% elsif arg_type.resolve <= Bool %}
      ({{arg}} != 0)
    {% elsif arg_type.resolve <= Int %}
      {{arg_type}}.new({{arg}})
    {% elsif arg_type.resolve <= Float %}
      {{arg_type}}.new({{arg}})
    {% elsif arg_type.resolve <= String %}
      {{arg_type}}.new({{arg}})
    {% elsif arg_type.resolve <= MrbWrap::Opt %}
      MrbMacro.convert_arg({{mrb}}, {{arg}}, {{arg_type.type_vars[0]}})
    {% else %}
      MrbMacro.convert_from_ruby_object({{mrb}}, {{arg}}, {{arg_type}}).value
    {% end %}
  end

  macro convert_keyword_arg(mrb, arg, arg_type)
    {% if arg_type.class_name == "TupleLiteral" %}
      if MrbCast.is_undef?({{arg}})
        {{arg_type[1]}}
      else
        MrbMacro.convert_keyword_arg({{mrb}}, {{arg}}, {{arg_type[0]}})
      end
    {% elsif arg_type.resolve <= Bool %}
      MrbCast.cast_to_bool({{mrb}}, {{arg}})
    {% elsif arg_type.resolve <= Int %}
      MrbCast.cast_to_int({{mrb}}, {{arg}})
    {% elsif arg_type.resolve <= Float %}
      MrbCast.cast_to_float({{mrb}}, {{arg}})
    {% elsif arg_type.resolve <= String %}
      MrbCast.cast_to_string({{mrb}}, {{arg}})
    {% elsif arg_type.resolve <= MrbWrap::Opt %}
      # TODO
    {% else %}
      MrbMacro.convert_from_ruby_object({{mrb}}, {{arg}}, {{arg_type}}).value
    {% end %}
  end

  macro convert_from_ruby_object(mrb, obj, crystal_type)
    # TODO: Add type check
    ptr = MrbInternal.get_data_ptr({{obj}})
    ptr.as({{crystal_type}}*)
  end

  macro call_and_return(mrb, proc, proc_args, converted_args)
    {% if proc.args.size != proc_args.size %}
      {% if proc_args.size > 0 %}
        return_value = {{proc.name}}.call(*{{converted_args}})
      {% else %}
        return_value = ({{proc.name}}).call
      {% end %}
    {% else %}
      {% if proc_args.size > 0 %}
        return_value = {{proc}}.call(*{{converted_args}})
      {% else %}
        return_value = ({{proc}}).call
      {% end %}
    {% end %}
    MrbCast.return_value({{mrb}}, return_value)
  end

  macro call_and_return_instance_method(mrb, proc, converted_obj, converted_args, operator = "")
    return_value = {{converted_obj}}.{{proc}}{{operator.id}}(*{{converted_args}})
    MrbCast.return_value({{mrb}}, return_value)
  end

  # :nodoc:
  macro call_and_return_keyword_instance_method(mrb, proc, converted_obj, converted_regular_args, keyword_args, kw_args, operator = "")
    return_value = {{converted_obj}}.{{proc}}{{operator.id}}(*{{converted_regular_args}},
      {% c = 0 %}
      {% for keyword in keyword_args.keys %}
        {{keyword.id}}: MrbMacro.convert_keyword_arg({{mrb}}, {{kw_args}}.values[{{c}}], {{keyword_args[keyword]}}),
        {% c += 1 %}
      {% end %}
    )
    MrbCast.return_value({{mrb}}, return_value)
  end

  macro convert_args(mrb, args, proc_args)
    Tuple.new(
      {% c = 0 %}
      {% for arg in proc_args %}
        MrbMacro.convert_arg({{mrb}}, {{args}}[{{c}}].value, {{arg}}),
        {% c += 1 %}
      {% end %}
    )
  end

  macro get_converted_args(mrb, proc_args)
    args = MrbMacro.generate_arg_tuple({{proc_args}})
    format_string = MrbMacro.format_string({{proc_args}})
    
    MrbInternal.mrb_get_args({{mrb}}, format_string, *args)

    MrbMacro.convert_args({{mrb}}, args, {{proc_args}})
  end

  # TODO: Simplify macro structure
  macro wrap_module_function_with_args(mrb_state, under_module, name, proc, proc_args = [] of Class)
    {% if proc_args.class_name == "ArrayLiteral" %}
      {% proc_arg_array = proc_args %}
    {% else %}
      {% proc_arg_array = [proc_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc_arg_array}})
      MrbMacro.call_and_return(mrb, {{proc}}, {{proc_arg_array}}, converted_args)
    end

    {{mrb_state}}.define_module_function({{name}}, {{under_module}}, wrapped_method)
  end

  macro wrap_class_method_with_args(mrb_state, crystal_class, name, proc, proc_args = [] of Class)
    {% if proc_args.class_name == "ArrayLiteral" %}
      {% proc_arg_array = proc_args %}
    {% else %}
      {% proc_arg_array = [proc_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc_arg_array}})
      MrbMacro.call_and_return(mrb, {{proc}}, {{proc_arg_array}}, converted_args)
    end

    {{mrb_state}}.define_class_method({{name}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro wrap_instance_function_with_args(mrb_state, crystal_class, name, proc, proc_args = [] of Class, operator = "")
    {% if proc_args.class_name == "ArrayLiteral" %}
      {% proc_arg_array = proc_args %}
    {% else %}
      {% proc_arg_array = [proc_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc_arg_array}})
      converted_obj = MrbMacro.convert_from_ruby_object(mrb, obj, {{crystal_class}}).value
      MrbMacro.call_and_return_instance_method(mrb, {{proc}}, converted_obj, converted_args, {{operator}})
    end

    {{mrb_state}}.define_method({{name + operator}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  # :nodoc:
  macro wrap_instance_function_with_keyword_args(mrb_state, crystal_class, name, proc, keyword_args, regular_args = [] of Class, use_other_keywords = false, operator = "")
    {% if regular_args.class_name == "ArrayLiteral" %}
      {% regular_arg_array = regular_args %}
    {% else %}
      {% regular_arg_array = [regular_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      regular_arg_tuple = MrbMacro.generate_arg_tuple({{regular_arg_array}})
      format_string = MrbMacro.format_string({{regular_arg_array}}) + ":"

      kw_names = [
        {% for keyword in keyword_args.keys %}
          {{keyword}}.to_s.to_unsafe,
        {% end %}
      ]

      # Keyword argument struct
      kw_args = MrbInternal::KWArgs.new
      kw_args.num = {{keyword_args}}.size
      kw_args.values = Pointer(MrbInternal::MrbValue).malloc(size: {{keyword_args}}.size)
      kw_args.table = kw_names
      kw_args.required = 0 # TODO: Count these
      kw_args.rest = Pointer(MrbInternal::MrbValue).malloc(size: 1)

      MrbInternal.mrb_get_args(mrb, format_string, *regular_arg_tuple, pointerof(kw_args))

      converted_regular_args = MrbMacro.convert_args(mrb, regular_arg_tuple, {{regular_arg_array}})
      converted_obj = MrbMacro.convert_from_ruby_object(mrb, obj, {{crystal_class}}).value

      MrbMacro.call_and_return_keyword_instance_method(mrb, {{proc}}, converted_obj, converted_regular_args, {{keyword_args}}, kw_args, {{operator}})
      MrbCast.return_value(mrb, nil)
    end

    {{mrb_state}}.define_method({{name + operator}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro wrap_constructor_function(mrb_state, crystal_class, proc, proc_args = [] of Class)
    {% if proc_args.class_name == "ArrayLiteral" %}
      {% proc_arg_array = proc_args %}
    {% else %}
      {% proc_arg_array = [proc_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      # Create local object
      {% if proc_arg_array.size > 0 %}
        converted_args = MrbMacro.get_converted_args(mrb, {{proc_arg_array}})
        new_obj = ({{proc}}).call(*converted_args)
      {% else %}
        new_obj = ({{proc}}).call
      {% end %}

      if new_obj.responds_to?(:mrb_initialize)
        new_obj.mrb_initialize(mrb)
      end

      # Allocate memory so we do not lose this object
      new_obj_ptr = Pointer({{crystal_class}}).malloc(size: 1, value: new_obj)
      MrbRefTable.add(new_obj_ptr.value.object_id, new_obj_ptr.as(Void*))

      destructor = MrbTypeCache.destructor_method({{crystal_class}})
      MrbInternal.set_data_ptr_and_type(obj, new_obj_ptr, MrbTypeCache.register({{crystal_class}}, destructor))

      # Return object
      obj
    end

    {{mrb_state}}.define_method("initialize", MrbClassCache.get({{crystal_class}}), wrapped_method)
  end
end
