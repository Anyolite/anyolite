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

end