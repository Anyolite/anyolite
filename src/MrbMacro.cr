# Helper methods which should not be used for trivial cases in the final version
module MrbMacro
  macro format_string(args)
    {% format_str = "" %}
    {% optional_values = false %}

    # TODO: Error if a required argument follows optional arguments

    {% for arg in args %}
      {% if arg.resolve <= Bool %}
        {% format_str += "b" %}
      {% elsif arg.resolve <= Int %}
        {% format_str += "i" %}
      {% elsif arg.resolve <= Float %}
        {% format_str += "f" %}
      {% elsif arg.resolve <= String %}
        {% format_str += "z" %}
      {% elsif arg.resolve <= MrbWrap::Opt %}
        {% if !optional_values %}
          {% format_str += "|" %}
          {% optional_values = true %}

          {% new_arg = arg.type_vars[0] %}
          {% if new_arg.resolve <= Bool %}
            {% format_str += "b" %}
          {% elsif new_arg.resolve <= Int %}
            {% format_str += "i" %}
          {% elsif new_arg.resolve <= Float %}
            {% format_str += "f" %}
          {% elsif new_arg.resolve <= String %}
            {% format_str += "z" %}
          {% elsif new_arg.resolve <= MrbWrap::Opt %}
            # Invalid
          {% else %}
            {% format_str += "o" %}
          {% end %}

        {% end %}
      {% else %}
        {% format_str += "o" %}
      {% end %}
    {% end %}

    {{format_str}}
  end

  macro format_string_without_first_arg(args)
    {% format_str = "" %}
    {% first_arg = true %}
    {% optional_values = false %}

    {% for arg in args %}
      {% if first_arg %}
        {% first_arg = false %}
      {% else %}
        {% if arg.resolve <= Bool %}
          {% format_str += "b" %}
        {% elsif arg.resolve <= Int %}
          {% format_str += "i" %}
        {% elsif arg.resolve <= Float %}
          {% format_str += "f" %}
        {% elsif arg.resolve <= String %}
          {% format_str += "z" %}
        {% elsif arg.resolve <= MrbWrap::Opt %}
          {% if !optional_values %}
            {% format_str += "|" %}
            {% optional_values = true %}
            
            {% new_arg = arg.type_vars[0] %}
            {% if new_arg.resolve <= Bool %}
              {% format_str += "b" %}
            {% elsif new_arg.resolve <= Int %}
              {% format_str += "i" %}
            {% elsif new_arg.resolve <= Float %}
              {% format_str += "f" %}
            {% elsif new_arg.resolve <= String %}
              {% format_str += "z" %}
            {% elsif new_arg.resolve <= MrbWrap::Opt %}
              # Invalid
            {% else %}
              {% format_str += "o" %}
            {% end %}

          {% end %}
        {% else %}
          {% format_str += "o" %}
        {% end %}
      {% end %}
    {% end %}

    {{format_str}}
  end

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
    {% elsif type.resolve <= MrbWrap::Opt %}

      {% new_type = type.type_vars[0] %} 
      {% if new_type.resolve <= Bool %}
        Pointer(MrbInternal::MrbBool)
      {% elsif new_type.resolve <= Int %}
        Pointer(MrbInternal::MrbInt)
      {% elsif new_type.resolve <= Float %}
        Pointer(MrbInternal::MrbFloat)
      {% elsif new_type.resolve <= String %}
        Pointer(LibC::Char*)
      {% elsif new_type.resolve <= MrbWrap::Opt %}
        # Invalid
      {% else %}
        Pointer(MrbInternal::MrbValue)
      {% end %}

    {% else %}
      Pointer(MrbInternal::MrbValue)
    {% end %}
  end

  macro generate_arg_tuple(args)
    Tuple.new(
      {% for arg in args %}
        {% if arg.resolve <= MrbWrap::Opt %}
          MrbMacro.pointer_type({{arg.type_vars[0]}}).malloc(size: 1, value: MrbMacro.type_in_ruby({{arg.type_vars[0]}}).new({{arg.type_vars[1]}})),
        {% else %}
          MrbMacro.pointer_type({{arg}}).malloc(size: 1),
        {% end %}
      {% end %}
    )
  end

  macro generate_arg_tuple_without_first_arg(args)
    Tuple.new(
      {% first_arg = true %}
      {% for arg in args %}
        {% if first_arg %}
          {% first_arg = false %}
        {% else %}
          {% if arg.resolve <= MrbWrap::Opt %}
            MrbMacro.pointer_type({{arg.type_vars[0]}}).malloc(size: 1, value: MrbMacro.type_in_ruby({{arg.type_vars[0]}}).new({{arg.type_vars[1]}})),
          {% else %}
            MrbMacro.pointer_type({{arg}}).malloc(size: 1),
          {% end %}
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
    {% if arg_type.resolve <= Bool %}
      ({{arg}} != 0)
    {% elsif arg_type.resolve <= Int %}
      {{arg_type}}.new({{arg}})
    {% elsif arg_type.resolve <= Float %}
      {{arg_type}}.new({{arg}})
    {% elsif arg_type.resolve <= String %}
      {{arg_type}}.new({{arg}})
    {% elsif arg_type.resolve <= MrbWrap::Opt %}

      {% new_type = arg_type.type_vars[0] %}
      {% if new_type.resolve <= Bool %}
        ({{arg}} != 0)
      {% elsif new_type.resolve <= Int %}
        {{new_type}}.new({{arg}})
      {% elsif new_type.resolve <= Float %}
        {{new_type}}.new({{arg}})
      {% elsif new_type.resolve <= String %}
        {{new_type}}.new({{arg}})
      {% elsif new_type.resolve <= MrbWrap::Opt %}
        # Invalid
      {% else %}
        MrbMacro.convert_from_ruby_object({{mrb}}, {{arg}}, {{new_type}}).value
      {% end %}

    # TODO: Pointer as possible class
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

  macro call_and_return_instance_method(mrb, proc, proc_args, converted_obj, converted_args)
    {% if proc.args.size != proc_args.size %}
      {% if proc_args.size > 1 %}
        return_value = {{proc.name}}.call({{converted_obj}}, *{{converted_args}})
      {% else %}
        return_value = ({{proc.name}}).call({{converted_obj}})
      {% end %}
    {% else %}
      {% if proc_args.size > 1 %}
        return_value = {{proc}}.call({{converted_obj}}, *{{converted_args}})
      {% else %}
        return_value = ({{proc}}).call({{converted_obj}})
      {% end %}
    {% end %}

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

  macro convert_args_without_first_arg(mrb, args, proc_args)
    Tuple.new(
      {% c = 0 %}
      {% for arg in proc_args %}
        {% if c > 0 %}
          MrbMacro.convert_arg({{mrb}}, {{args}}[{{c - 1}}].value, {{arg}}),
        {% end %}
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

  macro get_converted_args_without_first_arg(mrb, proc_args)
    args = MrbMacro.generate_arg_tuple_without_first_arg({{proc_args}})
    format_string = MrbMacro.format_string_without_first_arg({{proc_args}})
    
    MrbInternal.mrb_get_args({{mrb}}, format_string, *args)

    MrbMacro.convert_args_without_first_arg({{mrb}}, args, {{proc_args}})
  end

  macro wrap_module_function_with_args(mrb_state, under_module, name, proc, proc_args)
    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc_args}})
      MrbMacro.call_and_return(mrb, {{proc}}, {{proc_args}}, converted_args)
    end

    {{mrb_state}}.define_module_function({{name}}, {{under_module}}, wrapped_method)
  end

  macro wrap_class_method_with_args(mrb_state, crystal_class, name, proc, proc_args)
    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc_args}})
      MrbMacro.call_and_return(mrb, {{proc}}, {{proc_args}}, converted_args)
    end

    {{mrb_state}}.define_class_method({{name}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro wrap_instance_function_with_args(mrb_state, crystal_class, name, proc, proc_args)
    wrapped_method = MrbFunc.new do |mrb, obj|
      converted_args = MrbMacro.get_converted_args_without_first_arg(mrb, {{proc_args}})
      converted_obj = MrbMacro.convert_from_ruby_object(mrb, obj, {{crystal_class}}).value
      MrbMacro.call_and_return_instance_method(mrb, {{proc}}, {{proc_args}}, converted_obj, converted_args)
    end

    {{mrb_state}}.define_method({{name}}, MrbClassCache.get({{crystal_class}}), wrapped_method)
  end

  macro wrap_constructor_function(mrb_state, crystal_class, proc, proc_args)
    wrapped_method = MrbFunc.new do |mrb, obj|
      # Create local object
      {% if proc_args.size > 0 %}
        converted_args = MrbMacro.get_converted_args(mrb, {{proc_args}})
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
