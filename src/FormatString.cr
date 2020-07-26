module FormatString

  macro generate(proc)
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
  
end