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
    {% if proc.stringify == "MrbWrap::Empty" %}
      return_value = {{operator.id}}(*{{converted_args}})
    {% else %}
      return_value = {{proc}}{{operator.id}}(*{{converted_args}})
    {% end %}
    MrbCast.return_value({{mrb}}, return_value)
  end

  macro call_and_return_keyword_method(mrb, proc, converted_regular_args, keyword_args, kw_args, operator = "", empty_regular = false)
    {% if proc.stringify == "MrbWrap::Empty" %}
      return_value = {{operator.id}}(
    {% else %}
      return_value = {{proc}}{{operator.id}}(
    {% end %}
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
      {% if proc.stringify == "MrbWrap::Empty" %}
        return_value = {{converted_obj}}.content.{{operator.id}}(*{{converted_args}})
      {% else %}
        return_value = {{converted_obj}}.content.{{proc}}{{operator.id}}(*{{converted_args}})
      {% end %}
    else
      {% if proc.stringify == "MrbWrap::Empty" %}
        return_value = {{converted_obj}}.{{operator.id}}(*{{converted_args}})
      {% else %}
        return_value = {{converted_obj}}.{{proc}}{{operator.id}}(*{{converted_args}})
      {% end %}
    end
    MrbCast.return_value({{mrb}}, return_value)
  end

  macro call_and_return_keyword_instance_method(mrb, proc, converted_obj, converted_regular_args, keyword_args, kw_args, operator = "", empty_regular = false)
    if {{converted_obj}}.is_a?(MrbWrap::StructWrapper)
      {% if proc.stringify == "MrbWrap::Empty" %}
        return_value = {{converted_obj}}.content.{{operator.id}}(
      {% else %}
        return_value = {{converted_obj}}.content.{{proc}}{{operator.id}}(
      {% end %}
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
      {% if proc.stringify == "MrbWrap::Empty" %}
        return_value = {{converted_obj}}.{{operator.id}}(
      {% else %}
        return_value = {{converted_obj}}.{{proc}}{{operator.id}}(
      {% end %}
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

    {{mrb_state}}.define_method({{name}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
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

    {{mrb_state}}.define_method({{name}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
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

  macro wrap_method_index(mrb_state, crystal_class, method_index, ruby_name, 
    is_constructor = false, is_class_method = false, 
    operator = "", cut_name = nil, 
    without_keywords = false, added_keyword_args = nil)

    {% if is_class_method %}
      {% method = crystal_class.resolve.class.methods[method_index] %}
    {% else %}
      {% method = crystal_class.resolve.methods[method_index] %}
    {% end %}

    {% if !operator.empty? %}
      {% if cut_name %}
        {% final_method_name = cut_name %}
      {% else %}
        {% final_method_name = MrbWrap::Empty %}
      {% end %}
    {% else %}
      {% final_method_name = method.name %}
    {% end %}

    {% if method.args.empty? %}
      {% if is_class_method %}
        MrbWrap.wrap_class_method({{mrb_state}}, {{crystal_class}}, {{ruby_name}}, {{crystal_class}}.{{final_method_name}}, operator: {{operator}})
      {% elsif is_constructor %}
        MrbWrap.wrap_constructor({{mrb_state}}, {{crystal_class}})
      {% else %}
        MrbWrap.wrap_instance_method({{mrb_state}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, operator: {{operator}})
      {% end %}

    {% elsif method.args.stringify.includes?(":") || (added_keyword_args && added_keyword_args.stringify.includes?(":")) %}
      {% if without_keywords %}
        {% type_array = [] of Class %}

        {% for arg in method.args %}
          {% type_array.push(arg.restriction) %}
        {% end %}

        {% if is_class_method %}
          MrbWrap.wrap_class_method({{mrb_state}}, {{crystal_class}}, {{ruby_name}}, {{crystal_class}}.{{final_method_name}}, {{type_array}}, operator: {{operator}})
        {% elsif is_constructor %}
          MrbWrap.wrap_constructor({{mrb_state}}, {{crystal_class}}, {{type_array}}, operator: {{operator}})
        {% else %}
          MrbWrap.wrap_instance_method({{mrb_state}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, {{type_array}}, operator: {{operator}})
        {% end %}
      {% else %}
        {% keyword_hash = {} of Symbol => Crystal::Macros::ASTNode %}

        {% invalid = false %}

        {% if added_keyword_args %}
          {% for element in added_keyword_args %}
            {% next if invalid %}
            {% if element.value %}
              {% if !element.type %}
                {% puts "INFO: Could not wrap function '#{final_method_name}' with args #{added_keyword_args}." %}
                {% invalid = true %}
              {% else %}
                {% keyword_hash[element.var.symbolize] = {element.type, element.value} %}
              {% end %}
            {% else %}
              {% keyword_hash[element.var.symbolize] = element.type %}
            {% end %}
          {% end %}
        {% else %}
          {% for arg in method.args %}
            {% next if invalid %}
            {% if arg.default_value.stringify != "" %}
              {% if !arg.restriction %}
                {% puts "INFO: Could not wrap function '#{final_method_name}' with args #{method.args}." %}
                {% invalid = true %}
              {% else %}
                {% keyword_hash[arg.name.symbolize] = {arg.restriction, arg.default_value} %}
              {% end %}
            {% else %}
              {% keyword_hash[arg.name.symbolize] = arg.restriction %}
            {% end %}
          {% end %}
        {% end %}
        
        {% if !invalid %}
          {% if is_class_method %}
            MrbWrap.wrap_class_method_with_keywords({{mrb_state}}, {{crystal_class}}, {{ruby_name}}, {{crystal_class}}.{{final_method_name}}, {{keyword_hash}}, operator: {{operator}})
          {% elsif is_constructor %}
            MrbWrap.wrap_constructor_with_keywords({{mrb_state}}, {{crystal_class}}, {{keyword_hash}}, operator: {{operator}})
          {% else %}
            MrbWrap.wrap_instance_method_with_keywords({{mrb_state}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, {{keyword_hash}}, operator: {{operator}})
          {% end %}
        {% end %}
      {% end %}

    {% else %}
      {% if is_class_method %}
        {% puts "INFO: Could not wrap function '#{crystal_class}.#{method.name}' with args #{method.args}." %}
      {% else %}
        {% puts "INFO: Could not wrap function '#{method.name}' with args #{method.args}." %}
      {% end %}
    {% end %}
  end

  macro wrap_all_instance_methods(mrb_state, crystal_class, exclusions, verbose)
    {% has_specialized_method = {} of String => Bool %}

    {% for method in crystal_class.resolve.methods %}
      {% all_annotations_specialize_im = crystal_class.resolve.annotations(MrbWrap::SpecializeInstanceMethod) %}
      {% annotation_specialize_im = all_annotations_specialize_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% if method.annotation(MrbWrap::Specialize) %}
        {% has_specialized_method[method.name.stringify] = true %}
      {% end %}

      {% if annotation_specialize_im %}
        {% has_specialized_method[annotation_specialize_im[0].stringify] = true %}
      {% end %}
    {% end %}

    {% how_many_times_wrapped = {} of String => UInt32 %}

    {% for method, index in crystal_class.resolve.methods %}
      {% all_annotations_exclude_im = crystal_class.resolve.annotations(MrbWrap::ExcludeInstanceMethod) %}
      {% annotation_exclude_im = all_annotations_exclude_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_specialize_im = crystal_class.resolve.annotations(MrbWrap::SpecializeInstanceMethod) %}
      {% annotation_specialize_im = all_annotations_specialize_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_rename_im = crystal_class.resolve.annotations(MrbWrap::RenameInstanceMethod) %}
      {% annotation_rename_im = all_annotations_rename_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_without_keywords_im = crystal_class.resolve.annotations(MrbWrap::WrapWithoutKeywordsInstanceMethod) %}
      {% annotation_without_keyword_im = all_annotations_without_keywords_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% if method.annotation(MrbWrap::Rename) %}
        {% ruby_name = method.annotation(MrbWrap::Rename)[0].id %}
      {% elsif annotation_rename_im && method.name.stringify == annotation_rename_im[0].stringify %}
        {% ruby_name = annotation_rename_im[1].id %}
      {% else %}
        {% ruby_name = method.name %}
      {% end %}

      {% added_keyword_args = nil %}

      {% if method.annotation(MrbWrap::Specialize) && method.annotation(MrbWrap::Specialize)[1] %}
        {% added_keyword_args = method.annotation(MrbWrap::Specialize)[1] %}
      {% end %}

      {% if annotation_specialize_im && method.args.stringify == annotation_specialize_im[1].stringify %}
        {% added_keyword_args = annotation_specialize_im[2] %}
      {% end %}

      {% without_keywords = false %}

      {% if method.annotation(MrbWrap::WrapWithoutKeywords) || annotation_without_keyword_im %}
        {% without_keywords = true %}
      {% end %}

      {% puts "> Processing #{crystal_class}::#{method.name} to #{ruby_name}" if verbose %}
      # Ignore mrb hooks and finalize (unless specialized, but this is not recommended)
      {% if (method.name.starts_with?("mrb_") || method.name == "finalize") && !has_specialized_method[method.name.stringify] %}
      # Exclude methods if given as arguments
      {% elsif exclusions.includes?(method.name.symbolize) || exclusions.includes?(method.name) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion argument)" if verbose %}
      # Exclude methods which were annotated to be excluded
      {% elsif method.annotation(MrbWrap::Exclude) || (annotation_exclude_im) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion annotation)" if verbose %}
      # Exclude methods which are not the specialized methods
      {% elsif has_specialized_method[method.name.stringify] && !(method.annotation(MrbWrap::Specialize) || (annotation_specialize_im && method.args.stringify == annotation_specialize_im[1].stringify)) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} #{method.args} (Specialization 1)" if verbose %}
      # Handle operator methods (including setters)
      {% elsif method.name =~ /\W/ %}
        {% without_operator = method.name.gsub(/\W/, "") %}
        {% operator = method.name.tr(without_operator.stringify, "") %}

        {% if without_operator.empty? %}
          MrbMacro.wrap_method_index({{mrb_state}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", operator: "{{operator}}", without_keywords: true)
        {% else %}
          MrbMacro.wrap_method_index({{mrb_state}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", operator: "{{operator}}", cut_name: {{without_operator}}, without_keywords: true)
        {% end %}
      # Handle constructors
      {% elsif method.name == "initialize" %}
        MrbMacro.wrap_method_index({{mrb_state}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", is_constructor: true, without_keywords: {{without_keywords}}, added_keyword_args: {{added_keyword_args}})
        {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
      # Handle other instance methods
      {% else %}
        MrbMacro.wrap_method_index({{mrb_state}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", without_keywords: {{without_keywords}}, added_keyword_args: {{added_keyword_args}})
        {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
      {% end %}
    {% end %}
    
    # Make sure to add a default constructor if none was specified with Crystal

    {% if !how_many_times_wrapped["initialize"] %}
      MrbMacro.add_default_constructor({{mrb_state}}, {{crystal_class}}, {{verbose}})
    {% end %}
  end

  macro add_default_constructor(mrb_state, crystal_class, verbose)
    {% puts "> Adding constructor for #{crystal_class}" if verbose %}
    MrbWrap.wrap_constructor({{mrb_state}}, {{crystal_class}})
  end

  macro wrap_all_class_methods(mrb_state, crystal_class, exclusions, verbose)
    {% has_specialized_method = {} of String => Bool %}

    {% for method in crystal_class.resolve.class.methods %}
      {% all_annotations_specialize_im = crystal_class.resolve.annotations(MrbWrap::SpecializeClassMethod) %}
      {% annotation_specialize_im = all_annotations_specialize_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% if method.annotation(MrbWrap::Specialize) %}
        {% has_specialized_method[method.name.stringify] = true %}
      {% end %}

      {% if annotation_specialize_im %}
        {% has_specialized_method[annotation_specialize_im[0].stringify] = true %}
      {% end %}
    {% end %}

    {% how_many_times_wrapped = {} of String => UInt32 %}

    # TODO: Replace all im here with cm
    {% for method, index in crystal_class.resolve.class.methods %}
      {% all_annotations_exclude_im = crystal_class.resolve.annotations(MrbWrap::ExcludeClassMethod) %}
      {% annotation_exclude_im = all_annotations_exclude_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_specialize_im = crystal_class.resolve.annotations(MrbWrap::SpecializeClassMethod) %}
      {% annotation_specialize_im = all_annotations_specialize_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_rename_im = crystal_class.resolve.annotations(MrbWrap::RenameClassMethod) %}
      {% annotation_rename_im = all_annotations_rename_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_without_keywords_im = crystal_class.resolve.annotations(MrbWrap::WrapWithoutKeywordsClassMethod) %}
      {% annotation_without_keyword_im = all_annotations_without_keywords_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% if method.annotation(MrbWrap::Rename) %}
        {% ruby_name = method.annotation(MrbWrap::Rename)[0].id %}
      {% elsif annotation_rename_im && method.name.stringify == annotation_rename_im[0].stringify %}
        {% ruby_name = annotation_rename_im[1].id %}
      {% else %}
        {% ruby_name = method.name %}
      {% end %}

      {% added_keyword_args = nil %}

      {% if method.annotation(MrbWrap::Specialize) && method.annotation(MrbWrap::Specialize)[1] %}
        {% added_keyword_args = method.annotation(MrbWrap::Specialize)[1] %}
      {% end %}

      {% if annotation_specialize_im && method.args.stringify == annotation_specialize_im[1].stringify %}
        {% added_keyword_args = annotation_specialize_im[2] %}
      {% end %}

      {% without_keywords = false %}

      {% if method.annotation(MrbWrap::WrapWithoutKeywords) || annotation_without_keyword_im %}
        {% without_keywords = true %}
      {% end %}

      # We already wrapped 'initialize', so we don't need to wrap these
      {% if method.name == "allocate" || method.name == "new" %}
      # Exclude methods if given as arguments
      {% elsif exclusions.includes?(method.name.symbolize) || exclusions.includes?(method.name) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion argument)" if verbose %}
      # Exclude methods which were annotated to be excluded
      {% elsif method.annotation(MrbWrap::Exclude) || (annotation_exclude_im) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion annotation)" if verbose %}
      # Exclude methods which are not the specialized methods
      {% elsif has_specialized_method[method.name.stringify] && !(method.annotation(MrbWrap::Specialize) || (annotation_specialize_im && method.args.stringify == annotation_specialize_im[1].stringify)) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} (Specialization 1)" if verbose %}
      # Handle other class methods
      {% else %}
        MrbMacro.wrap_method_index({{mrb_state}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", is_class_method: true, without_keywords: {{without_keywords}}, added_keyword_args: {{added_keyword_args}})
        {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
      {% end %}
    {% end %}
  end

  macro wrap_all_constants(mrb_state, crystal_class, exclusions, verbose)
    {% for constant, index in crystal_class.resolve.constants %}
      {% all_annotations_exclude_im = crystal_class.resolve.annotations(MrbWrap::ExcludeConstant) %}
      {% annotation_exclude_im = all_annotations_exclude_im.find {|element| element[0].stringify == constant.stringify} %}

      {% all_annotations_rename_im = crystal_class.resolve.annotations(MrbWrap::RenameConstant) %}
      {% annotation_rename_im = all_annotations_rename_im.find {|element| element[0].stringify == constant.stringify} %}

      {% if annotation_rename_im && constant.stringify == annotation_rename_im[0].stringify %}
        {% ruby_name = annotation_rename_im[1].id %}
      {% else %}
        {% ruby_name = constant %}
      {% end %}

      # Exclude methods which were annotated to be excluded
      {% if exclusions.includes?(constant.symbolize) || exclusions.includes?(constant) %}
        {% puts "--> Excluding #{crystal_class}::#{constant} (Exclusion argument)" if verbose %}
      {% elsif annotation_exclude_im %}
        {% puts "--> Excluding #{crystal_class}::#{constant} (Exclusion annotation)" if verbose %}
      {% else %}
        MrbWrap.wrap_constant_under_class({{mrb_state}}, {{crystal_class}}, "{{ruby_name}}", {{crystal_class}}::{{constant}})
      {% end %}
    {% end %}
  end

end
