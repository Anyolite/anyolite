module Anyolite
  module Macro
    macro generate_arg_tuple(rb, args, context = nil)
      Tuple.new(
        {% if args %}
          {% for arg in args %}
            {% if arg.is_a?(TypeDeclaration) %}
              {% if arg.value %}
                {% if flag?(:use_general_object_format_chars) %}
                  Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::RbCast.return_value({{rb}}, {{arg.value}})),
                {% else %}
                  {% if arg.type.is_a?(Union) %}
                    # This does work, but I'm a bit surprised
                    Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::RbCast.return_value({{rb}}, {{arg.value}})),
                  {% elsif arg.type.resolve <= String %}
                    # The outer gods bless my wretched soul that this does neither segfault nor leak
                    Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: {{arg.value}}.to_unsafe),
                  {% elsif arg.type.resolve <= Anyolite::RbRef %}
                    Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: {{arg.value}}),
                  # NOTE: This might need some extensions
                  {% elsif arg.type.resolve <= Bool %}
                    Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::Macro.type_in_ruby({{arg}}, context: {{context}}).new({{arg.value}} ? 1 : 0)),
                  {% elsif arg.type.resolve <= Number %}
                    Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::Macro.type_in_ruby({{arg}}, context: {{context}}).new({{arg.value}})),
                  {% else %}
                    Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::RbCast.return_value({{rb}}, {{arg.value}})),
                  {% end %}
                {% end %}
              {% else %}
                Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1),
              {% end %}
            {% else %}
              Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1),
            {% end %}
          {% end %}
        {% end %}
      )
    end
  end
end