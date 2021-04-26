module Anyolite
  module Macro
    macro call_and_return(rb, proc, regular_args, converted_args, operator = "", return_nil = false)
      {% if proc.stringify == "Anyolite::Empty" %}
        return_value = {{operator.id}}(*{{converted_args}})
      {% else %}
        return_value = {{proc}}{{operator.id}}(*{{converted_args}})
      {% end %}

      {% if return_nil %}
        Anyolite::RbCast.return_nil
      {% else %}
        Anyolite::RbCast.return_value({{rb}}, return_value)
      {% end %}
    end

    macro call_and_return_keyword_method(rb, proc, converted_regular_args, keyword_args, kw_args, operator = "", 
      empty_regular = false, context = nil, type_vars = nil, type_var_names = nil, return_nil = false)

      {% if proc.stringify == "Anyolite::Empty" %}
        return_value = {{operator.id}}(
      {% else %}
        return_value = {{proc}}{{operator.id}}(
      {% end %}
        {% if empty_regular %}
          {% c = 0 %}
          {% for keyword in keyword_args %}
            {{keyword.var.id}}: Anyolite::Macro.convert_keyword_arg({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{context}}, 
              type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
            {% c += 1 %}
          {% end %}
        {% else %}
          *{{converted_regular_args}},
          {% c = 0 %}
          {% for keyword in keyword_args %}
            {{keyword.var.id}}: Anyolite::Macro.convert_keyword_arg({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{context}}}, 
              type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
            {% c += 1 %}
          {% end %}
        {% end %}
      )

      {% if return_nil %}
        Anyolite::RbCast.return_nil
      {% else %}
        Anyolite::RbCast.return_value({{rb}}, return_value)
      {% end %}
    end

    macro call_and_return_instance_method(rb, proc, converted_obj, converted_args, operator = "", return_nil = false)
      if {{converted_obj}}.is_a?(Anyolite::StructWrapper)
        working_content = {{converted_obj}}.content

        {% if proc.stringify == "Anyolite::Empty" %}
          return_value = working_content.{{operator.id}}(*{{converted_args}})
        {% else %}
          return_value = working_content.{{proc}}{{operator.id}}(*{{converted_args}})
        {% end %}

        {{converted_obj}}.content = working_content
      else
        {% if proc.stringify == "Anyolite::Empty" %}
          return_value = {{converted_obj}}.{{operator.id}}(*{{converted_args}})
        {% else %}
          return_value = {{converted_obj}}.{{proc}}{{operator.id}}(*{{converted_args}})
        {% end %}
      end

      {% if return_nil %}
        Anyolite::RbCast.return_nil
      {% else %}
        Anyolite::RbCast.return_value({{rb}}, return_value)
      {% end %}
    end

    macro call_and_return_keyword_instance_method(rb, proc, converted_obj, converted_regular_args, keyword_args, kw_args, operator = "",
                                                  empty_regular = false, context = nil, type_vars = nil, type_var_names = nil, return_nil = false)

      if {{converted_obj}}.is_a?(Anyolite::StructWrapper)
        working_content = {{converted_obj}}.content

        {% if proc.stringify == "Anyolite::Empty" %}
          return_value = working_content.{{operator.id}}(
        {% else %}
          return_value = working_content.{{proc}}{{operator.id}}(
        {% end %}
          {% if empty_regular %}
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_keyword_arg({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{context}}, 
                type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          {% else %}
            *{{converted_regular_args}},
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_keyword_arg({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{context}},
                type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          {% end %}
        )

        {{converted_obj}}.content = working_content
      else

        {% if proc.stringify == "Anyolite::Empty" %}
          return_value = {{converted_obj}}.{{operator.id}}(
        {% else %}
          return_value = {{converted_obj}}.{{proc}}{{operator.id}}(
        {% end %}
          {% if empty_regular %}
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_keyword_arg({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{context}},
                type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          {% else %}
            *{{converted_regular_args}},
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_keyword_arg({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{context}},
                type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          {% end %}
        )

      end

      {% if return_nil %}
        Anyolite::RbCast.return_nil
      {% else %}
        Anyolite::RbCast.return_value({{rb}}, return_value)
      {% end %}
    end
  end
end