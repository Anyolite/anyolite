module Anyolite
  module Macro
    macro format_string(args, context = nil)
      "" +
      {% if args %}
        {% for arg in args %}
          Anyolite::Macro.format_char({{arg}}, context: {{context}}) +
        {% end %}
      {% end %}
      ""
    end

    macro format_char(arg, optional_values = false, context = nil)
      {% if arg.is_a?(TypeDeclaration) %}
        {% if arg.type.is_a?(Union) %}
          {% if optional_values != true %}
            "|o"
          {% else %}
            "o"
          {% end %}
        {% elsif optional_values != true && arg.value %}
          "|" + Anyolite::Macro.format_char({{arg.type}}, optional_values: true, context: {{context}})
        {% else %}
          Anyolite::Macro.format_char({{arg.type}}, optional_values: {{optional_values}}, context: {{context}})
        {% end %}
      {% elsif context %}
        Anyolite::Macro.resolve_format_char({{context}}::{{arg.stringify.starts_with?("::") ? arg.stringify[2..-1].id  : arg}}, {{arg}}, {{context}})
      {% else %}
        Anyolite::Macro.resolve_format_char({{arg}}, {{arg}})
      {% end %}
    end

    macro resolve_format_char(arg, raw_arg, context = nil)
      {% if arg.resolve? %}
        {% if arg.resolve <= Bool %}
          "b"
        {% elsif arg.resolve <= Int || arg.resolve <= Pointer %}
          "i"
        {% elsif arg.resolve <= Float %}
          "f"
        {% elsif arg.resolve <= String %}
          "z"
        {% elsif arg.resolve <= Array %}
          "A"
        {% else %}
          "o"
        {% end %}
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(::)+/, "::").id %}
          Anyolite::Macro.resolve_format_char({{new_context}}::{{raw_arg.stringify.starts_with?("::") ? raw_arg.stringify[2..-1].id  : raw_arg}}, {{raw_arg}}, {{new_context}})
        {% else %}
          Anyolite::Macro.resolve_format_char({{raw_arg}}, {{raw_arg}})
        {% end %}
      {% else %}
        {% raise "Could not resolve #{arg}, which is a #{arg.class_name}, in any meaningful way" %}
      {% end %}
    end
  end
end