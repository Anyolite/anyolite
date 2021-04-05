module Anyolite
  module Macro
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
  end
end