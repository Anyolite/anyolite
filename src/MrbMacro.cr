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
      {% if optional_values != true %}
        "|" + MrbMacro.format_char({{arg[0]}}, optional_values: true)
      {% else %}
        MrbMacro.format_char({{arg[0]}}, optional_values: true)
      {% end %}
    {% elsif arg.resolve <= Bool %}
      "b"
    {% elsif arg.resolve <= Int %}
      "i"
    {% elsif arg.resolve <= Float %}
      "f"
    {% elsif arg.resolve <= String %}
      "z"
    {% else %}
      "o"
    {% end %}
  end

  macro type_in_ruby(type)
    {% if type.class_name == "TupleLiteral" %}
      MrbMacro.type_in_ruby({{type[0]}})  # TODO: Allow nil for regular arguments as default
    {% elsif type.resolve <= Bool %}
      MrbInternal::MrbBool
    {% elsif type.resolve <= Int %}
      MrbInternal::MrbInt
    {% elsif type.resolve <= Float %}
      MrbInternal::MrbFloat
    {% elsif type.resolve <= String %}  # TODO: Default string arguments do not work here yet, can this be fixed?
      LibC::Char*
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
    {% else %}
      Pointer(MrbInternal::MrbValue)
    {% end %}
  end

  macro generate_arg_tuple(args)
    Tuple.new(
      {% for arg in args %}
        {% if arg.class_name == "TupleLiteral" %}
          MrbMacro.pointer_type({{arg}}).malloc(size: 1, value: MrbMacro.type_in_ruby({{arg}}).new({{arg[1]}})),
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
    {% elsif arg_type.resolve <= Struct %}
      MrbMacro.convert_from_ruby_struct({{mrb}}, {{arg}}, {{arg_type}}).value.content
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
      {{arg_type}}.new(MrbCast.cast_to_int({{mrb}}, {{arg}}))
    {% elsif arg_type.resolve <= Float %}
     {{arg_type}}.new( MrbCast.cast_to_float({{mrb}}, {{arg}}))
    {% elsif arg_type.resolve <= String %}
      MrbCast.cast_to_string({{mrb}}, {{arg}})
    {% elsif arg_type.resolve <= Struct %}
      MrbMacro.convert_from_ruby_struct({{mrb}}, {{arg}}, {{arg_type}}).value.content
    {% else %}
      MrbMacro.convert_from_ruby_object({{mrb}}, {{arg}}, {{arg_type}}).value
    {% end %}
  end

  macro convert_from_ruby_object(mrb, obj, crystal_type)
    if MrbInternal.mrb_obj_is_kind_of({{mrb}}, {{obj}}, MrbClassCache.get({{crystal_type}})) == 0
      obj_class = MrbInternal.get_class_of_obj({{mrb}}, {{obj}})
      # TODO: Raise argument error in mruby instead
      raise("ERROR: Invalid data type #{obj_class} for object #{{{obj}}}:\n Should be #{{{crystal_type}}} -> MrbClassCache.get({{crystal_type}}) instead.")
    end

    ptr = MrbInternal.get_data_ptr({{obj}})
    ptr.as({{crystal_type}}*)
  end

  macro convert_from_ruby_struct(mrb, obj, crystal_type)
    if MrbInternal.mrb_obj_is_kind_of({{mrb}}, {{obj}}, MrbClassCache.get({{crystal_type}})) == 0
      obj_class = MrbInternal.get_class_of_obj({{mrb}}, {{obj}})
      # TODO: Raise argument error in mruby instead
      raise("ERROR: Invalid data type #{obj_class} for object #{{{obj}}}:\n Should be #{{{crystal_type}}} -> MrbClassCache.get({{crystal_type}}) instead.")
    end
    
    ptr = MrbInternal.get_data_ptr({{obj}})
    ptr.as(MrbWrap::StructWrapper({{crystal_type}})*)
  end

  macro call_and_return(mrb, proc, proc_args, converted_args, operator = "")
    return_value = {{proc}}{{operator.id}}(*{{converted_args}})
    MrbCast.return_value({{mrb}}, return_value)
  end

  macro call_and_return_keyword_method(mrb, proc, converted_regular_args, keyword_args, kw_args, operator = "", empty_regular = false)
    return_value = {{proc}}{{operator.id}}(
      {% if empty_regular %}
        {% c = 0 %}
        {% for keyword in keyword_args.keys %}
          {{keyword.id}}: MrbMacro.convert_keyword_arg({{mrb}}, {{kw_args}}.values[{{c}}], {{keyword_args[keyword]}}),
          {% c += 1 %}
        {% end %}
      {% else %}
        *{{converted_regular_args}},
        {% c = 0 %}
        {% for keyword in keyword_args.keys %}
          {{keyword.id}}: MrbMacro.convert_keyword_arg({{mrb}}, {{kw_args}}.values[{{c}}], {{keyword_args[keyword]}}),
          {% c += 1 %}
        {% end %}
      {% end %}
    )

    MrbCast.return_value({{mrb}}, return_value)
  end

  macro call_and_return_instance_method(mrb, proc, converted_obj, converted_args, operator = "")
    if {{converted_obj}}.is_a?(MrbWrap::StructWrapper)
      return_value = {{converted_obj}}.content.{{proc}}{{operator.id}}(*{{converted_args}})
    else
      return_value = {{converted_obj}}.{{proc}}{{operator.id}}(*{{converted_args}})
    end
    MrbCast.return_value({{mrb}}, return_value)
  end

  macro call_and_return_keyword_instance_method(mrb, proc, converted_obj, converted_regular_args, keyword_args, kw_args, operator = "", empty_regular = false)
    if {{converted_obj}}.is_a?(MrbWrap::StructWrapper)
      return_value = {{converted_obj}}.content.{{proc}}{{operator.id}}(
        {% if empty_regular %}
          {% c = 0 %}
          {% for keyword in keyword_args.keys %}
            {{keyword.id}}: MrbMacro.convert_keyword_arg({{mrb}}, {{kw_args}}.values[{{c}}], {{keyword_args[keyword]}}),
            {% c += 1 %}
          {% end %}
        {% else %}
          *{{converted_regular_args}},
          {% c = 0 %}
          {% for keyword in keyword_args.keys %}
            {{keyword.id}}: MrbMacro.convert_keyword_arg({{mrb}}, {{kw_args}}.values[{{c}}], {{keyword_args[keyword]}}),
            {% c += 1 %}
          {% end %}
        {% end %}
      )
    else
      return_value = {{converted_obj}}.{{proc}}{{operator.id}}(
        {% if empty_regular %}
          {% c = 0 %}
          {% for keyword in keyword_args.keys %}
            {{keyword.id}}: MrbMacro.convert_keyword_arg({{mrb}}, {{kw_args}}.values[{{c}}], {{keyword_args[keyword]}}),
            {% c += 1 %}
          {% end %}
        {% else %}
          *{{converted_regular_args}},
          {% c = 0 %}
          {% for keyword in keyword_args.keys %}
            {{keyword.id}}: MrbMacro.convert_keyword_arg({{mrb}}, {{kw_args}}.values[{{c}}], {{keyword_args[keyword]}}),
            {% c += 1 %}
          {% end %}
        {% end %}
      )
    end

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

  macro allocate_constructed_object(crystal_class, obj, new_obj)
    # Call initializer method if available
    if new_obj.responds_to?(:mrb_initialize)
      new_obj.mrb_initialize(mrb)
    end

    # Allocate memory so we do not lose this object
    if {{crystal_class}} <= Struct
      struct_wrapper = MrbWrap::StructWrapper({{crystal_class}}).new({{new_obj}})
      new_obj_ptr = Pointer(MrbWrap::StructWrapper({{crystal_class}})).malloc(size: 1, value: struct_wrapper)
      MrbRefTable.add(MrbRefTable.get_object_id(new_obj_ptr.value), new_obj_ptr.as(Void*))

      puts "> S: {{crystal_class}}: #{new_obj_ptr.value.inspect}" if MrbRefTable.option_active?(:logging)

      destructor = MrbTypeCache.destructor_method({{crystal_class}})
      MrbInternal.set_data_ptr_and_type({{obj}}, new_obj_ptr, MrbTypeCache.register({{crystal_class}}, destructor))
    else
      new_obj_ptr = Pointer({{crystal_class}}).malloc(size: 1, value: {{new_obj}})
      MrbRefTable.add(MrbRefTable.get_object_id(new_obj_ptr.value), new_obj_ptr.as(Void*))

      puts "> C: {{crystal_class}}: #{new_obj_ptr.value.inspect}" if MrbRefTable.option_active?(:logging)

      destructor = MrbTypeCache.destructor_method({{crystal_class}})
      MrbInternal.set_data_ptr_and_type({{obj}}, new_obj_ptr, MrbTypeCache.register({{crystal_class}}, destructor))
    end
  end

  macro generate_keyword_argument_struct(keyword_args)
    kw_names = MrbMacro.generate_keyword_names({{keyword_args}})
    kw_args = MrbInternal::KWArgs.new
    kw_args.num = {{keyword_args}}.size
    kw_args.values = Pointer(MrbInternal::MrbValue).malloc(size: {{keyword_args}}.size)
    kw_args.table = kw_names
    kw_args.required = {{keyword_args.values.select {|i| i.class_name != "TupleLiteral"}.size}}
    kw_args.rest = Pointer(MrbInternal::MrbValue).malloc(size: 1)
    kw_args
  end

  macro generate_keyword_names(keyword_args)
    [
      {% for keyword in keyword_args.keys %}
        {{keyword}}.to_s.to_unsafe,
      {% end %}
    ]
  end

  macro wrap_module_function_with_args(mrb_state, under_module, name, proc, proc_args = [] of Class)
    {% if proc_args.class_name == "ArrayLiteral" %}
      {% proc_arg_array = proc_args %}
    {% else %}
      {% proc_arg_array = [proc_args] %}
    {% end %}

    {% proc_arg_array = MrbMacro.put_args_in_array(proc_args) %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc_arg_array}})
      MrbMacro.call_and_return(mrb, {{proc}}, {{proc_arg_array}}, converted_args)
    end

    {{mrb_state}}.define_module_function({{name}}, MrbModuleCache.get({{under_module}}), wrapped_method)
  end

  macro wrap_module_function_with_keyword_args(mrb_state, under_module, name, proc, keyword_args, regular_args = [] of Class, operator = "")
    {% if regular_args.class_name == "ArrayLiteral" %}
      {% regular_arg_array = regular_args %}
    {% else %}
      {% regular_arg_array = [regular_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      regular_arg_tuple = MrbMacro.generate_arg_tuple({{regular_arg_array}})
      format_string = MrbMacro.format_string({{regular_arg_array}}) + ":"

      kw_args = MrbMacro.generate_keyword_argument_struct({{keyword_args}})
      MrbInternal.mrb_get_args(mrb, format_string, *regular_arg_tuple, pointerof(kw_args))

      converted_regular_args = MrbMacro.convert_args(mrb, regular_arg_tuple, {{regular_arg_array}})

      {% if regular_arg_array.size == 0 %}
        MrbMacro.call_and_return_keyword_method(mrb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, empty_regular: true)
      {% else %}
        MrbMacro.call_and_return_keyword_method(mrb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}})
      {% end %}
    end

    {{mrb_state}}.define_module_function({{name}}, MrbModuleCache.get({{under_module}}), wrapped_method)
  end

  macro wrap_class_method_with_args(mrb_state, crystal_class, name, proc, proc_args = [] of Class, operator = "")
    {% if proc_args.class_name == "ArrayLiteral" %}
      {% proc_arg_array = proc_args %}
    {% else %}
      {% proc_arg_array = [proc_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc_arg_array}})
      MrbMacro.call_and_return(mrb, {{proc}}, {{proc_arg_array}}, converted_args, operator: {{operator}})
    end
    
    {{mrb_state}}.define_class_method({{name}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro wrap_class_method_with_keyword_args(mrb_state, crystal_class, name, proc, keyword_args, regular_args = [] of Class, operator = "")
    {% if regular_args.class_name == "ArrayLiteral" %}
      {% regular_arg_array = regular_args %}
    {% else %}
      {% regular_arg_array = [regular_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      regular_arg_tuple = MrbMacro.generate_arg_tuple({{regular_arg_array}})
      format_string = MrbMacro.format_string({{regular_arg_array}}) + ":"

      kw_args = MrbMacro.generate_keyword_argument_struct({{keyword_args}})
      MrbInternal.mrb_get_args(mrb, format_string, *regular_arg_tuple, pointerof(kw_args))

      converted_regular_args = MrbMacro.convert_args(mrb, regular_arg_tuple, {{regular_arg_array}})

      {% if regular_arg_array.size == 0 %}
        MrbMacro.call_and_return_keyword_method(mrb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, empty_regular: true)
      {% else %}
        MrbMacro.call_and_return_keyword_method(mrb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}})
      {% end %}
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

      if {{crystal_class}} <= Struct
        converted_obj = MrbMacro.convert_from_ruby_struct(mrb, obj, {{crystal_class}}).value.content
      else
        converted_obj = MrbMacro.convert_from_ruby_object(mrb, obj, {{crystal_class}}).value
      end

      MrbMacro.call_and_return_instance_method(mrb, {{proc}}, converted_obj, converted_args, operator: {{operator}})
    end

    {{mrb_state}}.define_method({{name + operator}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro wrap_instance_function_with_keyword_args(mrb_state, crystal_class, name, proc, keyword_args, regular_args = [] of Class, operator = "")
    {% if regular_args.class_name == "ArrayLiteral" %}
      {% regular_arg_array = regular_args %}
    {% else %}
      {% regular_arg_array = [regular_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      regular_arg_tuple = MrbMacro.generate_arg_tuple({{regular_arg_array}})
      format_string = MrbMacro.format_string({{regular_arg_array}}) + ":"

      kw_args = MrbMacro.generate_keyword_argument_struct({{keyword_args}})
      MrbInternal.mrb_get_args(mrb, format_string, *regular_arg_tuple, pointerof(kw_args))

      converted_regular_args = MrbMacro.convert_args(mrb, regular_arg_tuple, {{regular_arg_array}})

      if {{crystal_class}} <= Struct
        converted_obj = MrbMacro.convert_from_ruby_struct(mrb, obj, {{crystal_class}}).value.content
      else
        converted_obj = MrbMacro.convert_from_ruby_object(mrb, obj, {{crystal_class}}).value
      end

      {% if regular_arg_array.size == 0 %}
        MrbMacro.call_and_return_keyword_instance_method(mrb, {{proc}}, converted_obj, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, empty_regular: true)
      {% else %}
        MrbMacro.call_and_return_keyword_instance_method(mrb, {{proc}}, converted_obj, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}})
      {% end %}
    end

    {{mrb_state}}.define_method({{name + operator}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro wrap_constructor_function_with_args(mrb_state, crystal_class, proc, proc_args = [] of Class, operator = "")
    {% if proc_args.class_name == "ArrayLiteral" %}
      {% proc_arg_array = proc_args %}
    {% else %}
      {% proc_arg_array = [proc_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc_arg_array}})
      new_obj = {{proc}}{{operator.id}}(*converted_args)

      MrbMacro.allocate_constructed_object({{crystal_class}}, obj, new_obj)
      obj
    end

    {{mrb_state}}.define_method("initialize", MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro wrap_constructor_function_with_keyword_args(mrb_state, crystal_class, proc, keyword_args, regular_args = [] of Class, operator = "")
    {% if regular_args.class_name == "ArrayLiteral" %}
      {% regular_arg_array = regular_args %}
    {% else %}
      {% regular_arg_array = [regular_args] %}
    {% end %}

    wrapped_method = MrbFunc.new do |mrb, obj|
      regular_arg_tuple = MrbMacro.generate_arg_tuple({{regular_arg_array}})
      format_string = MrbMacro.format_string({{regular_arg_array}}) + ":"

      kw_args = MrbMacro.generate_keyword_argument_struct({{keyword_args}})
      MrbInternal.mrb_get_args(mrb, format_string, *regular_arg_tuple, pointerof(kw_args))

      converted_regular_args = MrbMacro.convert_args(mrb, regular_arg_tuple, {{regular_arg_array}})

      {% if regular_arg_array.size == 0 %}
        new_obj = {{proc}}{{operator.id}}(
          {% c = 0 %}
          {% for keyword in keyword_args.keys %}
            {{keyword.id}}: MrbMacro.convert_keyword_arg(mrb, kw_args.values[{{c}}], {{keyword_args[keyword]}}),
            {% c += 1 %}
          {% end %}
        )
      {% else %}
        new_obj = {{proc}}{{operator.id}}(*converted_regular_args,
          {% c = 0 %}
          {% for keyword in keyword_args.keys %}
            {{keyword.id}}: MrbMacro.convert_keyword_arg(mrb, kw_args.values[{{c}}], {{keyword_args[keyword]}}),
            {% c += 1 %}
          {% end %}
        )
      {% end %}

      MrbMacro.allocate_constructed_object({{crystal_class}}, obj, new_obj)
      obj
    end

    {{mrb_state}}.define_method("initialize", MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro get_specialized_methods(crystal_class)
    specialized_methods = {} of String => Bool

    {% for method in crystal_class.resolve.methods %}
      {% all_annotations_specialize_im = crystal_class.resolve.annotations(MrbWrap::SpecializeInstanceMethod) %}
      {% annotation_specialize_im = all_annotations_specialize_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% if method.annotation(MrbWrap::Specialize) %}
        specialized_methods[{{method.name.stringify}}] = true
      {% elsif annotation_specialize_im %}
        specialized_methods[{{method.name.stringify}}] = true
      {% end %}
    {% end %}

    specialized_methods
  end

  macro is_forbidden_method?(method)
    {% if method.name.starts_with?("mrb_") || method.name == "finalize" %}
      true
    {% else %}
      false
    {% end %}
  end

  macro get_ruby_name(crystal_class, method)
    {% all_annotations_rename_im = crystal_class.resolve.annotations(MrbWrap::RenameInstanceMethod) %}
    {% annotation_rename_im = all_annotations_rename_im.find {|element| element[0].stringify == method.name.stringify} %}

    {% if method.annotation(MrbWrap::Rename) %}
      {{method.annotation(MrbWrap::Rename)[0].id.stringify}}
    {% elsif annotation_rename_im && method.name.stringify == annotation_rename_im[0].stringify %}
      {{annotation_rename_im[1].id.stringify}}
    {% else %}
      {{method.name.stringify}}
    {% end %}
  end
end
