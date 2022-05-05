module Anyolite
  module Macro
    macro format_string(args, options = {} of Symbol => NoReturn)
      "" +
      {% if args %}
        {% for arg in args %}
          Anyolite::Macro.format_char({{arg}}, options: {{options}}) +
        {% end %}
      {% end %}
      ""
    end

    macro format_char(arg, options = {} of Symbol => NoReturn)
      {% if arg.is_a?(TypeDeclaration) %}
        {% if arg.type.is_a?(Union) %}
          {% if options[:optional_values] != true %}
            "|o"
          {% else %}
            "o"
          {% end %}
        {% elsif options[:optional_values] != true && arg.value %}
          {% options[:optional_values] = true %}
          "|" + Anyolite::Macro.format_char({{arg.type}}, options: {{options}})
        {% else %}
          Anyolite::Macro.format_char({{arg.type}}, options: {{options}})
        {% end %}
      {% elsif options[:context] %}
        Anyolite::Macro.resolve_format_char({{options[:context]}}::{{arg.stringify.starts_with?("::") ? arg.stringify[2..-1].id : arg}}, {{arg}}, options: {{options}})
      {% else %}
        Anyolite::Macro.resolve_format_char({{arg}}, {{arg}})
      {% end %}
    end

    macro resolve_format_char(arg, raw_arg, options = {} of Symbol => NoReturn)
      {% if arg.resolve? %}
        {% if flag?(:use_general_object_format_chars) %}
          "o"
        {% else %}
          {% if arg.resolve <= Bool %}
            "b"
          {% elsif arg.resolve <= Int || arg.resolve <= Pointer %}
            "i"
          {% elsif arg.resolve <= Float || arg.resolve == Number %}
            "f"
          {% elsif arg.resolve <= String %}
            "z"
          {% elsif arg.resolve <= Array %}
            "A"
          {% elsif arg.resolve <= Anyolite::RbRef %}
            "o"
          {% else %}
            "o"
          {% end %}
        {% end %}
      {% elsif options[:context] %}
        {% if options[:context].names[0..-2].size > 0 %}
          {% new_context = options[:context].names[0..-2].join("::").gsub(/(::)+/, "::").id %}
          {% options[:context] = new_context %}
          Anyolite::Macro.resolve_format_char({{new_context}}::{{raw_arg.stringify.starts_with?("::") ? raw_arg.stringify[2..-1].id : raw_arg}}, {{raw_arg}}, options: {{options}})
        {% else %}
          # No context available anymore
          Anyolite::Macro.resolve_format_char({{raw_arg}}, {{raw_arg}})
        {% end %}
      {% else %}
        "o"
      {% end %}
    end
  end
end
