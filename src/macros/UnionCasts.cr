module Anyolite
  module Macro
    macro cast_to_union_value(rb, value, types, context = nil, debug_information = nil)
      final_value = :invalid

      {% for type in types %}
        {% if type.resolve? %}
          Anyolite::Macro.check_and_cast_union_type({{rb}}, {{value}}, {{type}}, {{type}}, context: {{context}})
        {% elsif context %}
          Anyolite::Macro.check_and_cast_union_type({{rb}}, {{value}}, {{context}}::{{type.stringify.starts_with?("::") ? type.stringify[2..-1].id : type}}, {{type}}, context: {{context}})
        {% else %}
          {% raise "Could not resolve type #{type}, which is a #{type.class_name}, in context #{context} (#{debug_information.id})" %}
        {% end %}
      {% end %}
      
      if final_value.is_a?(Symbol)
        # TODO: Better value description
        Anyolite::RbCast.casting_error({{rb}}, {{value}}, "{{types}}", nil)
        #Anyolite.raise_argument_error("Could not determine any value for #{{{value}}} with types {{types}} in context {{context}}")
        raise("Should not be reached")
      else
        final_value
      end
    end

    macro check_and_cast_union_type(rb, value, type, raw_type, context = nil, debug_information = nil)
      {% if type.resolve? %}
        Anyolite::Macro.check_and_cast_resolved_union_type({{rb}}, {{value}}, {{type}}, {{type}})
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          Anyolite::Macro.check_and_cast_union_type({{rb}}, {{value}}, {{new_context}}::{{raw_type.stringify.starts_with?("::") ? raw_type[2..-1] : raw_type}}, {{raw_type}}, {{new_context}})
        {% else %}
          Anyolite::Macro.check_and_cast_union_type({{rb}}, {{value}}, {{raw_type}}, {{raw_type}})
        {% end %}
      {% else %}
        {% raise "Could not resolve type #{type}, which is a #{type.class_name} (#{debug_information.id})" %}
      {% end %}
    end

    # TODO: Some double checks could be omitted

    macro check_and_cast_resolved_union_type(rb, value, type, raw_type, context = nil, debug_information = nil)
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
          begin
            final_value = Float64.new(Anyolite::RbCast.cast_to_float({{rb}}, {{value}}))
          rescue OverflowError
            Anyolite.raise_range_error("Overflow while casting #{Anyolite::RbCast.cast_to_float({{rb}}, {{value}})} to {{type}}.")
            Float64.new(0.0)
          end
        end
      {% elsif type.resolve == Int %}
        if Anyolite::RbCast.check_for_fixnum({{value}})
          begin
            final_value = Int64.new(Anyolite::RbCast.cast_to_int({{rb}}, {{value}}))
          rescue OverflowError
            Anyolite.raise_range_error("Overflow while casting #{Anyolite::RbCast.cast_to_int({{rb}}, {{value}})} to {{type}}.")
            Int64.new(0)
          end
        end
      {% elsif type.resolve <= Int %}
        if Anyolite::RbCast.check_for_fixnum({{value}})
          begin
            final_value = {{type}}.new(Anyolite::RbCast.cast_to_int({{rb}}, {{value}}))
          rescue OverflowError
            Anyolite.raise_range_error("Overflow while casting #{Anyolite::RbCast.cast_to_int({{rb}}, {{value}})} to {{type}}.")
            {{type}}.new(0)
          end
        end
      {% elsif type.resolve == Float %}
        if Anyolite::RbCast.check_for_float({{value}}) || Anyolite::RbCast.check_for_fixnum({{value}})
          begin
            final_value = Float64.new(Anyolite::RbCast.cast_to_float({{rb}}, {{value}}))
          rescue OverflowError
            Anyolite.raise_range_error("Overflow while casting #{Anyolite::RbCast.cast_to_int({{rb}}, {{value}})} to {{type}}.")
            Float64.new(0)
          end
        end
      {% elsif type.resolve <= Float %}
        if Anyolite::RbCast.check_for_float({{value}}) || Anyolite::RbCast.check_for_fixnum({{value}})
          begin
            final_value = {{type}}.new(Anyolite::RbCast.cast_to_float({{rb}}, {{value}}))
          rescue OverflowError
            Anyolite.raise_range_error("Overflow while casting #{Anyolite::RbCast.cast_to_int({{rb}}, {{value}})} to {{type}}.")
            {{type}}.new(0)
          end
        end
      {% elsif type.resolve <= Char %}
        if Anyolite::RbCast.check_for_string({{value}})
          final_value = Anyolite::RbCast.cast_to_char({{rb}}, {{value}})
        end
      {% elsif type.resolve <= String %}
        if Anyolite::RbCast.check_for_string({{value}}) || Anyolite::RbCast.check_for_symbol({{value}})
          final_value = Anyolite::RbCast.cast_to_string({{rb}}, {{value}})
        end
      {% elsif type.resolve <= Anyolite::RbRef %}
        final_value = {{type}}.new({{value}})
      {% elsif type.resolve <= Array %}
        if Anyolite::RbCast.check_for_array({{value}})
          array_size = Anyolite::RbCore.array_length({{value}})
          converted_array = {{type}}.new(size: array_size) do |i|
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, Anyolite::RbCore.rb_ary_entry({{value}}, i), {{type.type_vars[0]}})
          end
          final_value = converted_array
        end
      {% elsif type.resolve <= Hash %}
        if Anyolite::RbCast.check_for_hash({{value}})
        hash_size = Anyolite::RbCore.rb_hash_size({{rb}}, {{value}})

          all_rb_hash_keys = Anyolite::RbCore.rb_hash_keys({{rb}}, {{value}})
          all_converted_hash_keys = Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, all_rb_hash_keys, Array({{type.type_vars[0]}}), context: {{context}})

          converted_hash = {{type}}.new(initial_capacity: hash_size)
          all_converted_hash_keys.each_with_index do |key, i|
            rb_key = Anyolite::RbCore.rb_ary_entry(all_rb_hash_keys, i)
            rb_value = Anyolite::RbCore.rb_hash_get({{rb}}, {{value}}, rb_key)
            converted_hash[key] = Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, rb_value, {{type.type_vars[1]}}, context: {{context}})
          end

          final_value = converted_hash
        end
      {% elsif type.resolve <= Pointer %}
        if Anyolite::RbCast.check_for_data({{value}}) && Anyolite::RbCast.check_custom_type({{rb}}, {{value}}, Anyolite::HelperClasses::AnyolitePointer)
          %helper_ptr = Anyolite::Macro.convert_from_ruby_object({{rb}}, {{value}}, Anyolite::HelperClasses::AnyolitePointer).value
          final_value = {{type}}.new(address: %helper_ptr.address)
        end
      {% elsif type.resolve <= Struct || type.resolve <= Enum %}
        if Anyolite::RbCast.check_for_data({{value}}) && Anyolite::RbCast.check_custom_type({{rb}}, {{value}}, {{type}})
          final_value = Anyolite::Macro.convert_from_ruby_struct({{rb}}, {{value}}, {{type}}).value.content
        end
      {% elsif type.resolve? %}
        if Anyolite::RbCast.check_for_data({{value}}) && Anyolite::RbCast.check_custom_type({{rb}}, {{value}}, {{type}})
          final_value = Anyolite::Macro.convert_from_ruby_object({{rb}}, {{value}}, {{type}}).value
        end
      {% else %}
        {% raise "Could not resolve type #{type}, which is a #{type.class_name} (#{debug_information.id})" %}
      {% end %}
    end
  end
end