module Anyolite
  module Macro
    macro get_raw_args(rb, regular_args, context = nil)
      args = Anyolite::Macro.generate_arg_tuple({{rb}}, {{regular_args}}, context: {{context}})
      format_string = Anyolite::Macro.format_string({{regular_args}}, context: {{context}})
      Anyolite::RbCore.rb_get_args({{rb}}, format_string, *args)
      args
    end

    # Converts Ruby values to Crystal values
    macro convert_arg(rb, arg, arg_type, context = nil)
      {% if arg_type.stringify.includes?("->") || arg_type.stringify.includes?(" Proc(") %}
        {% puts "\e[33m> INFO: Proc types are not allowed as arguments.\e[0m" %}
        raise "Proc types are not allowed as arguments ({{debug_information.id}})"
      {% elsif arg_type.is_a?(Generic) && arg_type.name.stringify.gsub(/(\:\:)+/, "") == "Pointer" %}
        {% puts "\e[33m> INFO: Pointer types are not allowed as arguments.\e[0m" %}
        raise "Pointer types are not allowed as arguments ({{debug_information.id}})"
      {% elsif arg_type.is_a?(TypeDeclaration) && arg_type.type.is_a?(Union) %}
        Anyolite::Macro.convert_keyword_arg({{rb}}, {{arg}}, {{arg_type}}, context: {{context}})
      {% elsif arg_type.is_a?(TypeDeclaration) %}
        Anyolite::Macro.convert_arg({{rb}}, {{arg}}, {{arg_type.type}}, context: {{context}})
      {% elsif context %}
        Anyolite::Macro.convert_resolved_arg({{rb}}, {{arg}}, {{context}}::{{arg_type.stringify.starts_with?("::") ? arg_type.stringify[2..-1].id : arg_type}}, {{arg_type}}, {{context}})
      {% else %}
        Anyolite::Macro.convert_resolved_arg({{rb}}, {{arg}}, {{arg_type}}, {{arg_type}})
      {% end %}
    end

    macro convert_resolved_arg(rb, arg, arg_type, raw_arg_type, context = nil)
      {% if arg_type.resolve? %}
        {% if arg_type.resolve <= Bool %}
          ({{arg}} != 0)
        {% elsif arg_type.resolve == Number %}
          Float64.new({{arg}})
        {% elsif arg_type.resolve == Int %}
          Int64.new({{arg}})
        {% elsif arg_type.resolve <= Int %}
          {{arg_type}}.new({{arg}})
        {% elsif arg_type.resolve == Float %}
          Float64.new({{arg}})
        {% elsif arg_type.resolve <= Float %}
          {{arg_type}}.new({{arg}})
        {% elsif arg_type.resolve <= Char %}
          ({{arg}}.size > 0 ? {{arg_type}}.new({{arg}}[0] : '\0')
        {% elsif arg_type.resolve <= String %}
          {{arg_type}}.new({{arg}})
        {% elsif arg_type.resolve <= Struct || arg_type.resolve <= Enum %}
          Anyolite::Macro.convert_from_ruby_struct({{rb}}, {{arg}}, {{arg_type}}).value.content
        {% else %}
          Anyolite::Macro.convert_from_ruby_object({{rb}}, {{arg}}, {{arg_type}}).value
        {% end %}
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          Anyolite::Macro.convert_resolved_arg({{rb}}, {{arg}}, {{new_context}}::{{raw_arg_type.stringify.starts_with?("::") ? raw_arg_type.stringify[2..-1].id : raw_arg_type}}, {{raw_arg_type}}, {{new_context}})
        {% else %}
          Anyolite::Macro.convert_resolved_arg({{rb}}, {{arg}}, {{raw_arg_type}}, {{raw_arg_type}})
        {% end %}
      {% else %}
        {% raise "Could not resolve #{arg_type}, which is a #{arg_type.class_name}, in any meaningful way" %}
      {% end %}
    end

    macro convert_keyword_arg(rb, arg, arg_type, context = nil, type_vars = nil, type_var_names = nil, debug_information = nil)
      {% if arg_type.stringify.includes?("->") || arg_type.stringify.includes?(" Proc(") %}
        {% puts "\e[33m> INFO: Proc types are not allowed as arguments (#{debug_information.id}).\e[0m" %}
        raise "Proc types are not allowed as arguments ({{debug_information.id}})"
      {% elsif arg_type.is_a?(Generic) && arg_type.name.stringify.gsub(/(\:\:)+/, "") == "Pointer" %}
        {% puts "\e[33m> INFO: Pointer types are not allowed as arguments (#{debug_information.id}).\e[0m" %}
        raise "Pointer types are not allowed as arguments ({{debug_information.id}})"
      {% elsif type_var_names && type_var_names.includes?(arg_type.type) %}
        {% type_var_names.each_with_index { |element, index| result = index if element == arg_type.type } %}
        Anyolite::Macro.convert_keyword_arg({{rb}}, {{arg}}, {{type_vars[result]}}, context: {{context}}, debug_information: {{debug_information}})
      {% elsif type_var_names %}
        {% magical_regex = /([\(\s\:])([A-Z]+)([\),\s])/ %}
        {% replacement_arg_type = arg_type.type.stringify.gsub(magical_regex, "\\1\#\\2\#\\3") %}

        {% for type_var_name, index in type_var_names %}
          {% split_types = replacement_arg_type.split("\#") %}
          {% odd = true %}
          {% final_split_types = [] of ASTNode %}
          {% for split_type, split_type_index in split_types %}
            {% if !odd %}
              {% result = nil %}
              {% type_var_names.each_with_index { |element, index| result = index if element.stringify == split_type } %}
              {% if result %}
                {% final_split_types.push(type_vars[result].stringify) %}
              {% else %}
                {% final_split_types.push(split_type) %}
              {% end %}
            {% else %}
              {% final_split_types.push(split_type) %}
            {% end %}
            {% odd = !odd %}
          {% end %}
        {% end %}

        {% if arg_type.value %}
        {% final_type_def = "#{arg_type.var} : #{final_split_types.join("").id} = #{arg_type.value}" %}
        {% else %}
          {% final_type_def = "#{arg_type.var} : #{final_split_types.join("").id}" %}
        {% end %}

        Anyolite::Macro.convert_keyword_arg({{rb}}, {{arg}}, {{final_type_def.id}}, context: {{context}}, debug_information: {{debug_information}})
      {% elsif arg_type.is_a?(Call) %}
        Anyolite::Macro.convert_keyword_arg({{rb}}, {{arg}}, dummy_arg : {{arg_type}}, context: {{context}}, debug_information: {{debug_information}})
      {% elsif arg_type.is_a?(TypeDeclaration) %}
        if Anyolite::RbCast.is_undef?({{arg}})
          {% if arg_type.value || arg_type.value == false || arg_type.value == nil %}
            {{arg_type.value}}
          {% else %}
            # Should only happen if no default value was given
            Anyolite::RbCore.rb_raise_argument_error({{rb}}, "Undefined argument #{{{arg}}} of {{arg_type}} in context {{context}}")
            # Code should jump to somewhere else before this point, but we want to have a NoReturn type here
            raise("Should not be reached")
          {% end %}
        else
          {% if arg_type.type.is_a?(Union) %}
            Anyolite::Macro.convert_keyword_arg({{rb}}, {{arg}}, Union({{arg_type.type}}), context: {{context}}, debug_information: {{debug_information}})
          {% else %}
            Anyolite::Macro.convert_keyword_arg({{rb}}, {{arg}}, {{arg_type.type}}, context: {{context}}, debug_information: {{debug_information}})
          {% end %}
        end
      # TODO: Check if this might need some improvement
      {% elsif context && !arg_type.stringify.starts_with?("Union") %}
        Anyolite::Macro.convert_resolved_keyword_arg({{rb}}, {{arg}}, {{context}}::{{arg_type.stringify.starts_with?("::") ? arg_type.stringify[2..-1].id : arg_type}}, {{arg_type}}, context: {{context}}, debug_information: {{debug_information}})
      {% else %}
        Anyolite::Macro.convert_resolved_keyword_arg({{rb}}, {{arg}}, {{arg_type}}, {{arg_type}}, context: {{context}}, debug_information: {{debug_information}})
      {% end %}
    end

    macro convert_resolved_keyword_arg(rb, arg, arg_type, raw_arg_type, context = nil, debug_information = nil)
      {% if arg_type.stringify.starts_with?("Union") %}
        # This sadly needs some uncanny magic
        Anyolite::Macro.cast_to_union_value({{rb}}, {{arg}}, {{arg_type.stringify[6..-2].split('|').map { |x| x.id }}}, context: {{context}})
      {% elsif arg_type.resolve? %}
        {% if arg_type.resolve <= Nil %}
          Anyolite::RbCast.cast_to_nil({{rb}}, {{arg}})
        {% elsif arg_type.resolve <= Bool %}
          Anyolite::RbCast.cast_to_bool({{rb}}, {{arg}})
        {% elsif arg_type.resolve == Number %}
          Float64.new(Anyolite::RbCast.cast_to_float({{rb}}, {{arg}}))
        {% elsif arg_type.resolve == Int %}
          Int64.new(Anyolite::RbCast.cast_to_int({{rb}}, {{arg}}))
        {% elsif arg_type.resolve <= Int %}
          {{arg_type}}.new(Anyolite::RbCast.cast_to_int({{rb}}, {{arg}}))
        {% elsif arg_type.resolve == Float %}
          Float64.new(Anyolite::RbCast.cast_to_float({{rb}}, {{arg}}))
        {% elsif arg_type.resolve <= Float %}
          {{arg_type}}.new(Anyolite::RbCast.cast_to_float({{rb}}, {{arg}}))
        {% elsif arg_type.resolve <= Char %}
          Anyolite::RbCast.cast_to_char({{rb}}, {{arg}})
        {% elsif arg_type.resolve <= String %}
          Anyolite::RbCast.cast_to_string({{rb}}, {{arg}})
        {% elsif arg_type.resolve <= Struct || arg_type.resolve <= Enum %}
          Anyolite::Macro.convert_from_ruby_struct({{rb}}, {{arg}}, {{arg_type}}).value.content
        {% elsif arg_type.resolve? %}
          Anyolite::Macro.convert_from_ruby_object({{rb}}, {{arg}}, {{arg_type}}).value
        {% else %}
          {% raise "Could not resolve type #{arg_type}, which is a #{arg_type.class_name.id} (#{debug_information.id})" %}
        {% end %}
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          Anyolite::Macro.convert_resolved_keyword_arg({{rb}}, {{arg}}, {{new_context}}::{{raw_arg_type.stringify.starts_with?("::") ? raw_arg_type.stringify[2..-1].id : raw_arg_type}}, {{raw_arg_type}}, {{new_context}}, debug_information: {{debug_information}})
        {% else %}
          Anyolite::Macro.convert_resolved_keyword_arg({{rb}}, {{arg}}, {{raw_arg_type}}, {{raw_arg_type}}, debug_information: {{debug_information}})
        {% end %}
      {% else %}
        {% raise "Could not resolve type #{arg_type}, which is a #{arg_type.class_name.id} (#{debug_information.id})" %}
      {% end %}
    end

    macro convert_args(rb, args, regular_args, context)
      Tuple.new(
        {% c = 0 %}
        {% if regular_args %}
          {% for arg in regular_args %}
            Anyolite::Macro.convert_arg({{rb}}, {{args}}[{{c}}].value, {{arg}}, context: {{context}}),
            {% c += 1 %}
          {% end %}
        {% end %}
      )
    end

    macro get_converted_args(rb, regular_args, context)
      args = Anyolite::Macro.generate_arg_tuple({{rb}}, {{regular_args}}, context: {{context}})
      format_string = Anyolite::Macro.format_string({{regular_args}}, context: {{context}})
      
      Anyolite::RbCore.rb_get_args({{rb}}, format_string, *args)

      Anyolite::Macro.convert_args({{rb}}, args, {{regular_args}}, context: {{context}})
    end
  end
end