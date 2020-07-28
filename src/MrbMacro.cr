module MrbMacro

  macro format_string(proc)
    format_str = ""

    {% for arg in proc.args %}

      {% if arg.resolve <= Bool %}
        format_str += "b"
      {% elsif arg.resolve <= Int %}
        format_str += "i"
      {% elsif arg.resolve <= Float %}
        format_str += "f"
      {% elsif arg.resolve <= String %}
        format_str += "z"
      {% else %}
        format_str += "o"
      {% end %}
      
    {% end %}

    format_str
  end

  macro cast_type_to_ruby(type)
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

  macro get_converted_args(mrb, proc)
    args = MrbMacro.get_raw_args(mrb, {{proc}})
    # TODO: Convert arguments
    Tuple.new(Int32.new(args[0].value), (args[1].value != 0), String.new(args[2].value))
  end

  macro wrap_function(proc)
    MrbFunc.new do |mrb, self|
      converted_args = MrbMacro.get_converted_args(mrb, {{proc}})
      return_value = {{proc}}.call(*converted_args)
      # TODO: Cast return value correctly
      MrbCast.return_fixnum(return_value)
    end
  end

end