module Anyolite
  # Helper methods which should not be used for trivial cases in the final version
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
      {% if arg.stringify.includes?('|') %}
        {% if optional_values != true && arg.stringify.includes?('|') %}
          "|o"
        {% else %}
          "o"
        {% end %}
      {% elsif arg.is_a?(TypeDeclaration) %}
        {% if optional_values != true && arg.value %}
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
        {% elsif arg.resolve <= Int %}
          "i"
        {% elsif arg.resolve <= Float %}
          "f"
        {% elsif arg.resolve <= String %}
          "z"
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

    macro type_in_ruby(type, context = nil)
      {% if type.stringify.includes?('|') %}
        Anyolite::RbCore::RbValue
      {% elsif type.is_a?(TypeDeclaration) %}
        Anyolite::Macro.type_in_ruby({{type.type}})
      {% elsif context %}
        Anyolite::Macro.resolve_type_in_ruby({{context}}::{{type.stringify.starts_with?("::") ? type.stringify[2..-1].id  : type}}, {{type}}, {{context}})
      {% else %}
        Anyolite::Macro.resolve_type_in_ruby({{type}}, {{type}})
      {% end %}
    end

    macro resolve_type_in_ruby(type, raw_type, context = nil)
      {% if type.resolve? %}
        {% if type.resolve <= Bool %}
          Anyolite::RbCore::RbBool
        {% elsif type.resolve <= Int %}
          Anyolite::RbCore::RbInt
        {% elsif type.resolve <= Float %}
          Anyolite::RbCore::RbFloat
        {% elsif type.resolve <= String %}
          # Should actually never occur due to special handling before this function
          Pointer(LibC::Char)
        {% else %}
          Anyolite::RbCore::RbValue
        {% end %}
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          Anyolite::Macro.resolve_type_in_ruby({{new_context}}::{{raw_type.stringify.starts_with?("::") ? raw_type.stringify[2..-1].id : raw_type}}, {{raw_type}}, {{new_context}})
        {% else %}
          Anyolite::Macro.resolve_type_in_ruby({{raw_type}}, {{raw_type}})
        {% end %}
      {% else %}
        {% raise "Could not resolve #{type}, which is a #{type.class_name}, in any meaningful way" %}
      {% end %}
    end

    macro pointer_type(type, context = nil)
      {% if type.stringify.includes?('|') %}
        Pointer(Anyolite::RbCore::RbValue)
      {% elsif type.is_a?(TypeDeclaration) %}
        Anyolite::Macro.pointer_type({{type.type}}, context: {{context}})
      {% elsif context %}
        Anyolite::Macro.resolve_pointer_type({{context}}::{{type.stringify.starts_with?("::") ? type.stringify[2..-1].id : type}}, {{type}}, {{context}})
      {% else %}
        Anyolite::Macro.resolve_pointer_type({{type}}, {{type}})
      {% end %}
    end

    macro resolve_pointer_type(type, raw_type, context = nil)
      {% if type.resolve? %}
        {% if type.resolve <= Bool %}
          Pointer(Anyolite::RbCore::RbBool)
        {% elsif type.resolve <= Int %}
          Pointer(Anyolite::RbCore::RbInt)
        {% elsif type.resolve <= Float || type.resolve == Number %}
          Pointer(Anyolite::RbCore::RbFloat)
        {% elsif type.resolve <= String %}
          Pointer(LibC::Char*)
        {% else %}
          Pointer(Anyolite::RbCore::RbValue)
        {% end %}
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          Anyolite::Macro.resolve_pointer_type({{new_context}}::{{raw_type.stringify.starts_with?("::") ? raw_type.stringify[2..-1].id : raw_type}}, {{raw_type}}, {{new_context}})
        {% else %}
          Anyolite::Macro.resolve_pointer_type({{raw_type}}, {{raw_type}})
        {% end %}
      {% else %}
        {% raise "Could not resolve #{type}, which is a #{type.class_name}, in any meaningful way" %}
      {% end %}
    end

    macro generate_arg_tuple(rb, args, context = nil)
      Tuple.new(
        {% if args %}
          {% for arg in args %}
            {% if arg.is_a?(TypeDeclaration) %}
              {% if arg.value %}
                {% if arg.type.stringify.includes?('|') %}
                  # This does work, but I'm a bit surprised
                  Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::RbCast.return_value({{rb}}, {{arg.value}})),
                {% elsif arg.type.resolve <= String %}
                  # The outer gods bless my wretched soul that this does neither segfault nor leak
                  Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: {{arg.value}}.to_unsafe),
                {% else %}
                  Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::Macro.type_in_ruby({{arg}}, context: {{context}}).new({{arg.value}})),
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
      {% elsif arg_type.stringify.includes?('|') %}
        # This is kind of cheating, but hey, it does its job
        # ...
        # Please don't judge me
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
        {% elsif arg_type.resolve <= String %}
          {{arg_type}}.new({{arg}})
        {% elsif arg_type.resolve <= Struct %}
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
      # TODO: Is it possible to put the message somewhere else... or at least CATCH the exception?
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
        {% raise "Received Call #{arg_type} instead of TypeDeclaration or TypeNode" %}
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
          # Yes, this is not the elegant way
          # However, when a union type component moves out of its context, it is not resolvable by its own anymore
          # This then leads to problems, so it is better to test for '|' instead of using the resolve.union? method
          {% if arg_type.type.stringify.includes?('|') %}
            Anyolite::Macro.convert_keyword_arg({{rb}}, {{arg}}, Union({{arg_type.type}}), context: {{context}}, debug_information: {{debug_information}})
          {% else %}
            Anyolite::Macro.convert_keyword_arg({{rb}}, {{arg}}, {{arg_type.type}}, context: {{context}}, debug_information: {{debug_information}})
          {% end %}
        end
      {% elsif context && !arg_type.stringify.starts_with?("Union") %}
        Anyolite::Macro.convert_resolved_keyword_arg({{rb}}, {{arg}}, {{context}}::{{arg_type.stringify.starts_with?("::") ? arg_type.stringify[2..-1].id : arg_type}}, {{arg_type}}, context: {{context}}, debug_information: {{debug_information}})
      {% else %}
        Anyolite::Macro.convert_resolved_keyword_arg({{rb}}, {{arg}}, {{arg_type}}, {{arg_type}}, context: {{context}}, debug_information: {{debug_information}})
      {% end %}
    end

    macro convert_resolved_keyword_arg(rb, arg, arg_type, raw_arg_type, context = nil, debug_information = nil)
      {% if arg_type.stringify.includes?('|') %}
        # Same as above, this sadly needs some uncanny magic
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
        {% elsif arg_type.resolve <= String %}
          Anyolite::RbCast.cast_to_string({{rb}}, {{arg}})
        {% elsif arg_type.resolve <= Struct %}
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

    macro cast_to_union_value(rb, value, types, context = nil)
      final_value = :invalid

      {% for type in types %}
        {% if type.resolve? %}
          Anyolite::Macro.check_and_cast_union_type({{rb}}, {{value}}, {{type}}, {{type}}, context: {{context}})
        {% elsif context %}
          Anyolite::Macro.check_and_cast_union_type({{rb}}, {{value}}, {{context}}::{{type.stringify.starts_with?("::") ? type.stringify[2..-1].id : type}}, {{type}}, context: {{context}})
        {% else %}
          {% raise "Could not resolve type #{type}, which is a #{type.class_name}, in context #{context}" %}
        {% end %}
      {% end %}
      
      if final_value.is_a?(Symbol)
        Anyolite::RbCore.rb_raise_argument_error({{rb}}, "Could not determine any value for #{{{value}}} with types {{types}} in context {{context}}")
        raise("Should not be reached")
      else
        final_value
      end
    end

    macro check_and_cast_union_type(rb, value, type, raw_type, context = nil)
      {% if type.resolve? %}
        Anyolite::Macro.check_and_cast_resolved_union_type({{rb}}, {{value}}, {{type}}, {{type}})
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          Anyolite::Macro.check_and_cast_resolved_union_type({{rb}}, {{value}}, {{new_context}}::{{raw_type.stringify.starts_with?("::") ? raw_type[2..-1] : raw_type}}, {{raw_type}}, {{new_context}})
        {% else %}
          Anyolite::Macro.check_and_cast_resolved_union_type({{rb}}, {{value}}, {{raw_type}}, {{raw_type}})
        {% end %}
      {% else %}
        {% raise "Could not resolve type #{type}, which is a #{type.class_name}" %}
      {% end %}
    end

    # TODO: Some double checks could be omitted

    macro check_and_cast_resolved_union_type(rb, value, type, raw_type, context = nil)
      {% if type.resolve <= Nil %}
        if Anyolite::RbCast.check_for_nil({{value}})
          final_value = Anyolite::RbCast.cast_to_nil({{rb}}, {{value}})
        end
      {% elsif type.resolve <= Bool %}
        if Anyolite::RbCast.check_for_bool({{value}})
          final_value = Anyolite::RbCast.cast_to_bool({{rb}}, {{value}})
        end
      {% elsif type.resolve == Number %}
        if Anyolite::RbCast.check_for_float({{value}})
          final_value = Float64.new(Anyolite::RbCast.cast_to_float({{rb}}, {{value}}))
        end
      {% elsif type.resolve == Int %}
        if Anyolite::RbCast.check_for_fixnum({{value}})
          final_value = Int64.new(Anyolite::RbCast.cast_to_int({{rb}}, {{value}}))
        end
      {% elsif type.resolve <= Int %}
        if Anyolite::RbCast.check_for_fixnum({{value}})
          final_value = {{type}}.new(Anyolite::RbCast.cast_to_int({{rb}}, {{value}}))
        end
      {% elsif type.resolve == Float %}
        if Anyolite::RbCast.check_for_float({{value}})
          final_value = Float64.new(Anyolite::RbCast.cast_to_float({{rb}}, {{value}}))
        end
      {% elsif type.resolve <= Float %}
        if Anyolite::RbCast.check_for_float({{value}})
          final_value = {{type}}.new(Anyolite::RbCast.cast_to_float({{rb}}, {{value}}))
        end
      {% elsif type.resolve <= String %}
        if Anyolite::RbCast.check_for_string({{value}})
          final_value = Anyolite::RbCast.cast_to_string({{rb}}, {{value}})
        end
      {% elsif type.resolve <= Struct %}
        if Anyolite::RbCast.check_for_data({{value}}) && Anyolite::RbCast.check_custom_type({{rb}}, {{value}}, {{type}})
          final_value = Anyolite::Macro.convert_from_ruby_struct({{rb}}, {{value}}, {{type}}).value.content
        end
      {% elsif type.resolve? %}
        if Anyolite::RbCast.check_for_data({{value}}) && Anyolite::RbCast.check_custom_type({{rb}}, {{value}}, {{type}})
          final_value = Anyolite::Macro.convert_from_ruby_object({{rb}}, {{value}}, {{type}}).value
        end
      {% else %}
        {% raise "Could not resolve type #{type}, which is a #{type.class_name}" %}
      {% end %}
    end

    macro convert_from_ruby_object(rb, obj, crystal_type)
      if !Anyolite::RbCast.check_custom_type({{rb}}, {{obj}}, {{crystal_type}})
        obj_class = Anyolite::RbCore.get_class_of_obj({{rb}}, {{obj}})
        Anyolite::RbCore.rb_raise_argument_error({{rb}}, "Invalid data type #{obj_class} for object #{{{obj}}}:\n Should be #{{{crystal_type}}} -> Anyolite::RbClassCache.get({{crystal_type}}) instead.")
      end

      ptr = Anyolite::RbCore.get_data_ptr({{obj}})
      ptr.as({{crystal_type}}*)
    end

    macro convert_from_ruby_struct(rb, obj, crystal_type)
      if !Anyolite::RbCast.check_custom_type({{rb}}, {{obj}}, {{crystal_type}})
        obj_class = Anyolite::RbCore.get_class_of_obj({{rb}}, {{obj}})
        Anyolite::RbCore.rb_raise_argument_error({{rb}}, "Invalid data type #{obj_class} for object #{{{obj}}}:\n Should be #{{{crystal_type}}} -> Anyolite::RbClassCache.get({{crystal_type}}) instead.")
      end
      
      ptr = Anyolite::RbCore.get_data_ptr({{obj}})
      ptr.as(Anyolite::StructWrapper({{crystal_type}})*)
    end

    macro call_and_return(rb, proc, regular_args, converted_args, operator = "")
      {% if proc.stringify == "Anyolite::Empty" %}
        return_value = {{operator.id}}(*{{converted_args}})
      {% else %}
        return_value = {{proc}}{{operator.id}}(*{{converted_args}})
      {% end %}
      Anyolite::RbCast.return_value({{rb}}, return_value)
    end

    macro call_and_return_keyword_method(rb, proc, converted_regular_args, keyword_args, kw_args, operator = "", 
      empty_regular = false, context = nil, type_vars = nil, type_var_names = nil)

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

      Anyolite::RbCast.return_value({{rb}}, return_value)
    end

    macro call_and_return_instance_method(rb, proc, converted_obj, converted_args, operator = "")
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
      Anyolite::RbCast.return_value({{rb}}, return_value)
    end

    macro call_and_return_keyword_instance_method(rb, proc, converted_obj, converted_regular_args, keyword_args, kw_args, operator = "",
                                                  empty_regular = false, context = nil, type_vars = nil, type_var_names = nil)

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

      Anyolite::RbCast.return_value({{rb}}, return_value)
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

    macro allocate_constructed_object(crystal_class, obj, new_obj)
      # Call initializer method if available
      if new_obj.responds_to?(:rb_initialize)
        new_obj.rb_initialize(rb)
      end

      # Allocate memory so we do not lose this object
      if {{crystal_class}} <= Struct
        struct_wrapper = Anyolite::StructWrapper({{crystal_class}}).new({{new_obj}})
        new_obj_ptr = Pointer(Anyolite::StructWrapper({{crystal_class}})).malloc(size: 1, value: struct_wrapper)
        Anyolite::RbRefTable.add(Anyolite::RbRefTable.get_object_id(new_obj_ptr.value), new_obj_ptr.as(Void*))

        puts "> S: {{crystal_class}}: #{new_obj_ptr.value.inspect}" if Anyolite::RbRefTable.option_active?(:logging)

        destructor = Anyolite::RbTypeCache.destructor_method({{crystal_class}})
        Anyolite::RbCore.set_data_ptr_and_type({{obj}}, new_obj_ptr, Anyolite::RbTypeCache.register({{crystal_class}}, destructor))
      else
        new_obj_ptr = Pointer({{crystal_class}}).malloc(size: 1, value: {{new_obj}})
        Anyolite::RbRefTable.add(Anyolite::RbRefTable.get_object_id(new_obj_ptr.value), new_obj_ptr.as(Void*))

        puts "> C: {{crystal_class}}: #{new_obj_ptr.value.inspect}" if Anyolite::RbRefTable.option_active?(:logging)

        destructor = Anyolite::RbTypeCache.destructor_method({{crystal_class}})
        Anyolite::RbCore.set_data_ptr_and_type({{obj}}, new_obj_ptr, Anyolite::RbTypeCache.register({{crystal_class}}, destructor))
      end
    end

    macro generate_keyword_argument_struct(rb_interpreter, keyword_args)
      kw_names = Anyolite::Macro.generate_keyword_names({{rb_interpreter}}, {{keyword_args}})
      kw_args = Anyolite::RbCore::KWArgs.new
      kw_args.num = {{keyword_args.size}}
      kw_args.values = Pointer(Anyolite::RbCore::RbValue).malloc(size: {{keyword_args.size}})
      kw_args.table = kw_names
      kw_args.required = {{keyword_args.select { |i| !i.var }.size}}
      kw_args.rest = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
      kw_args
    end

    macro generate_keyword_names(rb_interpreter, keyword_args)
      [
        {% for keyword in keyword_args %}
          Anyolite::RbCore.convert_to_rb_sym({{rb_interpreter}}, {{keyword.var.stringify}}),
        {% end %}
      ]
    end

    macro wrap_module_function_with_args(rb_interpreter, under_module, name, proc, regular_args = nil, context = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      {% proc_arg_array = Anyolite::Macro.put_args_in_array(regular_args) %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        converted_args = Anyolite::Macro.get_converted_args(rb, {{proc_arg_array}}, context: {{context}})
        Anyolite::Macro.call_and_return(rb, {{proc}}, {{proc_arg_array}}, converted_args)
      end

      {{rb_interpreter}}.define_module_function({{name}}, Anyolite::RbClassCache.get({{under_module}}), wrapped_method)
    end

    macro wrap_module_function_with_keyword_args(rb_interpreter, under_module, name, proc, keyword_args, regular_args = nil, operator = "", context = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        regular_arg_tuple = Anyolite::Macro.generate_arg_tuple({{rb_interpreter}}, {{regular_arg_array}}, context: {{context}})
        format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":"

        kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
        Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args))

        converted_regular_args = Anyolite::Macro.convert_args(rb, regular_arg_tuple, {{regular_arg_array}}, context: {{context}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          Anyolite::Macro.call_and_return_keyword_method(rb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, empty_regular: true, context: {{context}})
        {% else %}
          Anyolite::Macro.call_and_return_keyword_method(rb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, context: {{context}})
        {% end %}
      end

      {{rb_interpreter}}.define_module_function({{name}}, Anyolite::RbClassCache.get({{under_module}}), wrapped_method)
    end

    macro wrap_class_method_with_args(rb_interpreter, crystal_class, name, proc, regular_args = nil, operator = "", context = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        converted_args = Anyolite::Macro.get_converted_args(rb, {{regular_arg_array}}, context: {{context}})
        Anyolite::Macro.call_and_return(rb, {{proc}}, {{regular_arg_array}}, converted_args, operator: {{operator}})
      end
      
      {{rb_interpreter}}.define_class_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_class_method_with_keyword_args(rb_interpreter, crystal_class, name, proc, keyword_args, regular_args = nil, operator = "", context = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        regular_arg_tuple = Anyolite::Macro.generate_arg_tuple({{rb_interpreter}}, {{regular_arg_array}}, context: {{context}})
        format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":"

        kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
        Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args))

        converted_regular_args = Anyolite::Macro.convert_args(rb, regular_arg_tuple, {{regular_arg_array}}, context: {{context}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          Anyolite::Macro.call_and_return_keyword_method(rb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, 
            empty_regular: true, context: {{context}}, type_vars: {{type_vars}}, type_var_names: {{type_var_names}})
        {% else %}
          Anyolite::Macro.call_and_return_keyword_method(rb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, 
            context: {{context}}, type_vars: {{type_vars}}, type_var_names: {{type_var_names}})
        {% end %}
      end

      {{rb_interpreter}}.define_class_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_instance_function_with_args(rb_interpreter, crystal_class, name, proc, regular_args = nil, operator = "", context = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        converted_args = Anyolite::Macro.get_converted_args(rb, {{regular_arg_array}}, context: {{context}})

        if {{crystal_class}} <= Struct
          converted_obj = Anyolite::Macro.convert_from_ruby_struct(rb, obj, {{crystal_class}}).value
        else
          converted_obj = Anyolite::Macro.convert_from_ruby_object(rb, obj, {{crystal_class}}).value
        end

        Anyolite::Macro.call_and_return_instance_method(rb, {{proc}}, converted_obj, converted_args, operator: {{operator}})
      end

      {{rb_interpreter}}.define_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_instance_function_with_keyword_args(rb_interpreter, crystal_class, name, proc, keyword_args, regular_args = nil, operator = "", context = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        regular_arg_tuple = Anyolite::Macro.generate_arg_tuple({{rb_interpreter}}, {{regular_arg_array}}, context: {{context}})
        format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":"

        kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
        Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args))

        converted_regular_args = Anyolite::Macro.convert_args(rb, regular_arg_tuple, {{regular_arg_array}}, context: {{context}})

        if {{crystal_class}} <= Struct
          converted_obj = Anyolite::Macro.convert_from_ruby_struct(rb, obj, {{crystal_class}}).value
        else
          converted_obj = Anyolite::Macro.convert_from_ruby_object(rb, obj, {{crystal_class}}).value
        end

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          Anyolite::Macro.call_and_return_keyword_instance_method(rb, {{proc}}, converted_obj, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, 
            empty_regular: true, context: {{context}}, type_vars: {{type_vars}}, type_var_names: {{type_var_names}})
        {% else %}
          Anyolite::Macro.call_and_return_keyword_instance_method(rb, {{proc}}, converted_obj, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, 
            context: {{context}}, type_vars: {{type_vars}}, type_var_names: {{type_var_names}})
        {% end %}
      end

      {{rb_interpreter}}.define_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_constructor_function_with_args(rb_interpreter, crystal_class, proc, regular_args = nil, operator = "", context = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        converted_args = Anyolite::Macro.get_converted_args(rb, {{regular_arg_array}}, context: {{context}})
        new_obj = {{proc}}{{operator.id}}(*converted_args)

        Anyolite::Macro.allocate_constructed_object({{crystal_class}}, obj, new_obj)
        obj
      end

      {{rb_interpreter}}.define_method("initialize", Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_constructor_function_with_keyword_args(rb_interpreter, crystal_class, proc, keyword_args, regular_args = nil, operator = "", context = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        regular_arg_tuple = Anyolite::Macro.generate_arg_tuple({{rb_interpreter}}, {{regular_arg_array}}, context: {{context}})
        format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":"

        kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
        Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args))

        converted_regular_args = Anyolite::Macro.convert_args(rb, regular_arg_tuple, {{regular_arg_array}}, context: {{context}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          new_obj = {{proc}}{{operator.id}}(
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_keyword_arg(rb, kw_args.values[{{c}}], {{keyword}}, context: {{context}}, 
                type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          )
        {% else %}
          new_obj = {{proc}}{{operator.id}}(*converted_regular_args,
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_keyword_arg(rb, kw_args.values[{{c}}], {{keyword}}, context: {{context}}, 
                type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          )
        {% end %}

        Anyolite::Macro.allocate_constructed_object({{crystal_class}}, obj, new_obj)
        obj
      end

      {{rb_interpreter}}.define_method("initialize", Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_method_index(rb_interpreter, crystal_class, method_index, ruby_name,
                            is_constructor = false, is_class_method = false,
                            operator = "", cut_name = nil,
                            without_keywords = false, added_keyword_args = nil,
                            context = nil)

      {% if is_class_method %}
        {% method = crystal_class.resolve.class.methods[method_index] %}
      {% else %}
        {% method = crystal_class.resolve.methods[method_index] %}
      {% end %}

      {% if !operator.empty? %}
        {% if cut_name %}
          {% if is_class_method %}
            {% final_method_name = "#{crystal_class}.#{cut_name}".id %}
            {% final_operator = "#{crystal_class}.#{operator.id}" %}
          {% else %}
            {% final_method_name = cut_name %}
            {% final_operator = operator %}
          {% end %}
        {% else %}
          {% final_method_name = Anyolite::Empty %}
          {% if is_class_method %}
            {% final_operator = "#{crystal_class}.#{operator.id}" %}
          {% else %}
            {% final_operator = operator %}
          {% end %}
        {% end %}
      {% else %}
        {% if is_class_method %}
          {% final_method_name = "#{crystal_class}.#{method.name}".id %}
        {% else %}
          {% final_method_name = method.name %}
        {% end %}
        {% final_operator = operator %}
      {% end %}

      {% final_arg_array = added_keyword_args ? added_keyword_args : method.args %}

      {% if final_arg_array.empty? %}
        {% if is_class_method %}
          Anyolite.wrap_class_method({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, operator: {{final_operator}}, context: {{context}})
        {% elsif is_constructor %}
          Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}}, context: {{context}})
        {% else %}
          Anyolite.wrap_instance_method({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, operator: {{final_operator}}, context: {{context}})
        {% end %}

      # A complicated check, but it is more stable than simply checking for colons
      {% elsif final_arg_array.find { |m| (m.is_a?(TypeDeclaration) && m.type) || (m.is_a?(Arg) && m.restriction) } %}
        {% if without_keywords %}
          {% if without_keywords >= final_arg_array.size %}
            {% regular_arg_partition = nil %}
            {% keyword_arg_partition = final_arg_array %}
          {% elsif without_keywords < 0 %}
            {% regular_arg_partition = final_arg_array %}
            {% keyword_arg_partition = nil %}
          {% else %}
            {% regular_arg_partition = final_arg_array[0 .. without_keywords - 1] %}
            {% keyword_arg_partition = final_arg_array[without_keywords .. -1] %}
          {% end %}

          {% if keyword_arg_partition %}
            {% if is_class_method %}
              Anyolite.wrap_class_method_with_keywords({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
                {{keyword_arg_partition}}, regular_args: {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}})
            {% elsif is_constructor %}
              Anyolite.wrap_constructor_with_keywords({{rb_interpreter}}, {{crystal_class}}, 
                {{keyword_arg_partition}}, regular_args: {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}})
            {% else %}
              Anyolite.wrap_instance_method_with_keywords({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
                {{keyword_arg_partition}}, regular_args: {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}})
            {% end %}
          {% else %}
            {% if is_class_method %}
              Anyolite.wrap_class_method({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
                {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}})
            {% elsif is_constructor %}
              Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}}, 
                {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}})
            {% else %}
              Anyolite.wrap_instance_method({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
                {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}})
            {% end %}
          {% end %}
        {% else %}
          {% if is_class_method %}
            Anyolite.wrap_class_method_with_keywords({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
              {{final_arg_array}}, operator: {{final_operator}}, context: {{context}})
          {% elsif is_constructor %}
            Anyolite.wrap_constructor_with_keywords({{rb_interpreter}}, {{crystal_class}}, 
              {{final_arg_array}}, operator: {{final_operator}}, context: {{context}})
          {% else %}
            Anyolite.wrap_instance_method_with_keywords({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
              {{final_arg_array}}, operator: {{final_operator}}, context: {{context}})
          {% end %}
        {% end %}

      {% else %}
        {% if is_class_method %}
          {% puts "\e[33m> INFO: Could not wrap function '#{crystal_class}.#{method.name}' with args #{method.args}.\e[0m" %}
        {% else %}
          {% puts "\e[33m> INFO: Could not wrap function '#{method.name}' with args #{method.args}.\e[0m" %}
        {% end %}
      {% end %}
    end

    macro wrap_all_instance_methods(rb_interpreter, crystal_class, exclusions, verbose, context = nil, use_enum_constructor = false)
      {% has_specialized_method = {} of String => Bool %}

      {% for method in crystal_class.resolve.methods %}
        {% all_annotations_specialize_im = crystal_class.resolve.annotations(Anyolite::SpecializeInstanceMethod) %}
        {% annotation_specialize_im = all_annotations_specialize_im.find { |element| element[0].stringify == method.name.stringify || element[0] == method.name.stringify } %}

        {% if method.annotation(Anyolite::Specialize) %}
          {% has_specialized_method[method.name.stringify] = true %}
        {% end %}

        {% if annotation_specialize_im %}
          {% has_specialized_method[annotation_specialize_im[0].id.stringify] = true %}
        {% end %}
      {% end %}

      {% how_many_times_wrapped = {} of String => UInt32 %}

      {% for method, index in crystal_class.resolve.methods %}
        {% all_annotations_exclude_im = crystal_class.resolve.annotations(Anyolite::ExcludeInstanceMethod) %}
        {% annotation_exclude_im = all_annotations_exclude_im.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_specialize_im = crystal_class.resolve.annotations(Anyolite::SpecializeInstanceMethod) %}
        {% annotation_specialize_im = all_annotations_specialize_im.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_rename_im = crystal_class.resolve.annotations(Anyolite::RenameInstanceMethod) %}
        {% annotation_rename_im = all_annotations_rename_im.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_without_keywords_im = crystal_class.resolve.annotations(Anyolite::WrapWithoutKeywordsInstanceMethod) %}
        {% annotation_without_keyword_im = all_annotations_without_keywords_im.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% if method.annotation(Anyolite::Rename) %}
          {% ruby_name = method.annotation(Anyolite::Rename)[0].id %}
        {% elsif annotation_rename_im && method.name.stringify == annotation_rename_im[0].stringify %}
          {% ruby_name = annotation_rename_im[1].id %}
        {% else %}
          {% ruby_name = method.name %}
        {% end %}

        {% added_keyword_args = nil %}

        {% if method.annotation(Anyolite::Specialize) && method.annotation(Anyolite::Specialize)[0] %}
          {% added_keyword_args = method.annotation(Anyolite::Specialize)[0] %}
        {% end %}

        {% if annotation_specialize_im && (method.args.stringify == annotation_specialize_im[1].stringify || (method.args.stringify == "[]" && annotation_specialize_im[1] == nil)) %}
          {% added_keyword_args = annotation_specialize_im[2] %}
        {% end %}

        {% without_keywords = false %}

        {% if method.annotation(Anyolite::WrapWithoutKeywords) %}
          {% without_keywords = method.annotation(Anyolite::WrapWithoutKeywords)[0] ? method.annotation(Anyolite::WrapWithoutKeywords)[0] : -1 %}
        {% elsif annotation_without_keyword_im %}
          {% without_keywords = annotation_without_keyword_im[1] ? annotation_without_keyword_im[1] : -1 %}
        {% end %}

        {% puts "> Processing instance method #{crystal_class}::#{method.name} to #{ruby_name}\n--> Args: #{method.args}" if verbose %}
        
        # Ignore private and protected methods (can't be called from outside, they'd need to be wrapped for this to work)
        {% if method.visibility != :public && method.name != "initialize" %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion due to visibility)" if verbose %}
        # Ignore rb hooks, to_unsafe and finalize (unless specialized, but this is not recommended)
        {% elsif (method.name.starts_with?("rb_") || method.name == "finalize" || method.name == "to_unsafe") && !has_specialized_method[method.name.stringify] %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion by default)" if verbose %}
        # Exclude methods if given as arguments
        {% elsif exclusions.includes?(method.name.symbolize) || exclusions.includes?(method.name.stringify) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion argument)" if verbose %}
        # Exclude methods which were annotated to be excluded
        {% elsif method.annotation(Anyolite::Exclude) || (annotation_exclude_im) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion annotation)" if verbose %}
        # Exclude methods which are not the specialized methods
        {% elsif has_specialized_method[method.name.stringify] && !(method.annotation(Anyolite::Specialize) || (annotation_specialize_im && (method.args.stringify == annotation_specialize_im[1].stringify || (method.args.stringify == "[]" && annotation_specialize_im[1] == nil)))) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} #{method.args} (Specialization)" if verbose %}
        # Handle operator methods (including setters) by just transferring the original name into the operator
        # TODO: This might still be a source for potential bugs, so this code might need some reworking in the future
        {% elsif method.name[-1..-1] =~ /\W/ %}
          {% operator = ruby_name %}

          Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", operator: "{{operator}}", without_keywords: -1, context: {{context}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        # Handle constructors
        {% elsif method.name == "initialize" && use_enum_constructor == false %}
          Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", is_constructor: true, without_keywords: {{without_keywords}}, added_keyword_args: {{added_keyword_args}}, context: {{context}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        # Handle other instance methods
        {% else %}
          Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", without_keywords: {{without_keywords}}, added_keyword_args: {{added_keyword_args}}, context: {{context}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        {% end %}

        {% if how_many_times_wrapped[ruby_name.stringify] && how_many_times_wrapped[ruby_name.stringify] > 1 %}
          {% puts "\e[31m> WARNING: Method #{crystal_class}::#{ruby_name}\n--> New arguments: #{method.args}\n--> Wrapped more than once (#{how_many_times_wrapped[ruby_name.stringify]}).\e[0m" %}
        {% end %}
        {% puts "" if verbose %}
      {% end %}
      
      # Make sure to add a default constructor if none was specified with Crystal

      {% if !how_many_times_wrapped["initialize"] && !use_enum_constructor %}
        Anyolite::Macro.add_default_constructor({{rb_interpreter}}, {{crystal_class}}, {{verbose}})
      {% elsif !how_many_times_wrapped["initialize"] && use_enum_constructor %}
        Anyolite::Macro.add_enum_constructor({{rb_interpreter}}, {{crystal_class}}, {{verbose}})
      {% end %}
    end

    macro add_default_constructor(rb_interpreter, crystal_class, verbose)
      {% puts "> Adding constructor for #{crystal_class}\n\n" if verbose %}
      Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}})
    end

    macro add_enum_constructor(rb_interpreter, crystal_class, verbose)
      {% puts "> Adding enum constructor for #{crystal_class}\n\n" if verbose %}
      Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}}, [Int32])
    end

    macro wrap_all_class_methods(rb_interpreter, crystal_class, exclusions, verbose, context = nil)
      {% has_specialized_method = {} of String => Bool %}

      {% for method in crystal_class.resolve.class.methods %}
        {% all_annotations_specialize_im = crystal_class.resolve.annotations(Anyolite::SpecializeClassMethod) %}
        {% annotation_specialize_im = all_annotations_specialize_im.find { |element| element[0].stringify == method.name.stringify || element[0] == method.name.stringify } %}

        {% if method.annotation(Anyolite::Specialize) %}
          {% has_specialized_method[method.name.stringify] = true %}
        {% end %}

        {% if annotation_specialize_im %}
          {% has_specialized_method[annotation_specialize_im[0].id.stringify] = true %}
        {% end %}
      {% end %}

      {% how_many_times_wrapped = {} of String => UInt32 %}

      # TODO: Replace all im here with cm
      {% for method, index in crystal_class.resolve.class.methods %}
        {% all_annotations_exclude_im = crystal_class.resolve.annotations(Anyolite::ExcludeClassMethod) %}
        {% annotation_exclude_im = all_annotations_exclude_im.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_specialize_im = crystal_class.resolve.annotations(Anyolite::SpecializeClassMethod) %}
        {% annotation_specialize_im = all_annotations_specialize_im.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_rename_im = crystal_class.resolve.annotations(Anyolite::RenameClassMethod) %}
        {% annotation_rename_im = all_annotations_rename_im.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_without_keywords_im = crystal_class.resolve.annotations(Anyolite::WrapWithoutKeywordsClassMethod) %}
        {% annotation_without_keyword_im = all_annotations_without_keywords_im.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% if method.annotation(Anyolite::Rename) %}
          {% ruby_name = method.annotation(Anyolite::Rename)[0].id %}
        {% elsif annotation_rename_im && method.name.stringify == annotation_rename_im[0].stringify %}
          {% ruby_name = annotation_rename_im[1].id %}
        {% else %}
          {% ruby_name = method.name %}
        {% end %}

        {% added_keyword_args = nil %}

        {% if method.annotation(Anyolite::Specialize) && method.annotation(Anyolite::Specialize)[1] %}
          {% added_keyword_args = method.annotation(Anyolite::Specialize)[1] %}
        {% end %}

        {% if annotation_specialize_im && (method.args.stringify == annotation_specialize_im[1].stringify || (method.args.stringify == "[]" && annotation_specialize_im[1] == nil)) %}
          {% added_keyword_args = annotation_specialize_im[2] %}
        {% end %}

        {% without_keywords = false %}

        {% if method.annotation(Anyolite::WrapWithoutKeywords) %}
          {% without_keywords = method.annotation(Anyolite::WrapWithoutKeywords)[0] ? method.annotation(Anyolite::WrapWithoutKeywords)[0] : -1 %}
        {% elsif annotation_without_keyword_im %}
          {% without_keywords = annotation_without_keyword_im[1] ? annotation_without_keyword_im[1] : -1 %}
        {% end %}

        {% puts "> Processing class method #{crystal_class}::#{method.name} to #{ruby_name}\n--> Args: #{method.args}" if verbose %}
        
        # Ignore private and protected methods (can't be called from outside, they'd need to be wrapped for this to work)
        {% if method.visibility != :public %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion due to visibility)" if verbose %}
        # We already wrapped 'initialize', so we don't need to wrap these
        {% elsif method.name == "allocate" || method.name == "new" %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Allocation method)" if verbose %}
        # Exclude methods if given as arguments
        {% elsif exclusions.includes?(method.name.symbolize) || exclusions.includes?(method.name) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion argument)" if verbose %}
        # Exclude methods which were annotated to be excluded
        {% elsif method.annotation(Anyolite::Exclude) || (annotation_exclude_im) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion annotation)" if verbose %}
        # Exclude methods which are not the specialized methods
        {% elsif has_specialized_method[method.name.stringify] && !(method.annotation(Anyolite::Specialize) || (annotation_specialize_im && (method.args.stringify == annotation_specialize_im[1].stringify || (method.args.stringify == "[]" && annotation_specialize_im[1] == nil)))) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Specialization)" if verbose %}
        {% elsif method.name[-1..-1] =~ /\W/ %}
          {% operator = ruby_name %}

          Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", operator: "{{operator}}", is_class_method: true, without_keywords: -1, context: {{context}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        # Handle other class methods
        {% else %}
          Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", is_class_method: true, without_keywords: {{without_keywords}}, added_keyword_args: {{added_keyword_args}}, context: {{context}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        {% end %}

        {% if how_many_times_wrapped[ruby_name.stringify] && how_many_times_wrapped[ruby_name.stringify] > 1 %}
          {% puts "\e[31m> WARNING: Method #{crystal_class}::#{ruby_name}\n--> New arguments: #{method.args}\n--> Wrapped more than once (#{how_many_times_wrapped[ruby_name.stringify]}).\e[0m" %}
        {% end %}
        {% puts "" if verbose %}
      {% end %}
    end

    macro wrap_all_constants(rb_interpreter, crystal_class, exclusions, verbose, context = nil)
      # TODO: Is the context needed here?

      # NOTE: This check is necessary due to https://github.com/crystal-lang/crystal/issues/5757
      {% if crystal_class.resolve.type_vars.empty? %}
        {% for constant, index in crystal_class.resolve.constants %}
          {% all_annotations_exclude_im = crystal_class.resolve.annotations(Anyolite::ExcludeConstant) %}
          {% annotation_exclude_im = all_annotations_exclude_im.find { |element| element[0].id.stringify == constant.stringify } %}

          {% all_annotations_rename_im = crystal_class.resolve.annotations(Anyolite::RenameConstant) %}
          {% annotation_rename_im = all_annotations_rename_im.find { |element| element[0].id.stringify == constant.stringify } %}

          {% if annotation_rename_im && constant.stringify == annotation_rename_im[0].stringify %}
            {% ruby_name = annotation_rename_im[1].id %}
          {% else %}
            {% ruby_name = constant %}
          {% end %}

          {% puts "> Processing constant #{crystal_class}::#{constant} to #{ruby_name}" if verbose %}
          # Exclude methods which were annotated to be excluded
          {% if exclusions.includes?(constant.symbolize) || exclusions.includes?(constant) %}
            {% puts "--> Excluding #{crystal_class}::#{constant} (Exclusion argument)" if verbose %}
          {% elsif annotation_exclude_im %}
            {% puts "--> Excluding #{crystal_class}::#{constant} (Exclusion annotation)" if verbose %}
          {% else %}
            Anyolite::Macro.wrap_constant_or_class({{rb_interpreter}}, {{crystal_class}}, "{{ruby_name}}", {{constant}}, {{verbose}})
          {% end %}
          {% puts "" if verbose %}
        {% end %}
      {% end %}
    end

    macro wrap_constant_or_class(rb_interpreter, under_class_or_module, ruby_name, value, verbose = false)
      {% actual_constant = under_class_or_module.resolve.constant(value.id) %}
      {% if actual_constant.is_a?(TypeNode) %}
        {% if actual_constant.module? %}
          Anyolite.wrap_module_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, verbose: {{verbose}})
        {% elsif actual_constant.class? || actual_constant.struct? %}
          Anyolite.wrap_class_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, verbose: {{verbose}})
        {% elsif actual_constant.union? %}
          {% puts "\e[31m> WARNING: Wrapping of unions not supported, thus skipping #{actual_constant}\e[0m" %}
        {% elsif actual_constant < Enum %}
          Anyolite.wrap_class_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, use_enum_constructor: true, verbose: {{verbose}})
        {% else %}
          # Could be an alias, just try the default case
          Anyolite.wrap_class_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, verbose: {{verbose}})
        {% end %}
      {% else %}
        Anyolite.wrap_constant_under_class({{rb_interpreter}}, {{under_class_or_module}}, {{ruby_name}}, {{under_class_or_module}}::{{value}})
      {% end %}
    end
  end
end
