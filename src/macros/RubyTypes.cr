module Anyolite
  module Macro
    macro type_in_ruby(type, context = nil)
      {% if type.is_a?(TypeDeclaration) %}
        {% if type.type.is_a?(Union) %}
          Anyolite::RbCore::RbValue
        {% else %}
          Anyolite::Macro.type_in_ruby({{type.type}})
        {% end %}
      {% elsif context %}
        Anyolite::Macro.resolve_type_in_ruby({{context}}::{{type.stringify.starts_with?("::") ? type.stringify[2..-1].id : type}}, {{type}}, {{context}})
      {% else %}
        Anyolite::Macro.resolve_type_in_ruby({{type}}, {{type}})
      {% end %}
    end

    macro resolve_type_in_ruby(type, raw_type, context = nil)
      {% if type.resolve? %}
        {% if flag?(:use_general_object_format_chars) %}
          Anyolite::RbCore::RbValue
        {% else %}
          {% if type.resolve <= Bool %}
            Anyolite::RbCore::RbBool
          {% elsif type.resolve <= Int || type.resolve <= Pointer %}
            Anyolite::RbCore::RbInt
          {% elsif type.resolve <= Float || type.resolve == Number %}
            Anyolite::RbCore::RbFloat
          {% elsif type.resolve <= String %}
            # Should actually never occur due to special handling before this function
            Pointer(LibC::Char)
          {% elsif type.resolve <= Anyolite::RbRef %}
            Anyolite::RbCore::RbValue
          {% elsif type.resolve <= Array %}
            Anyolite::RbCore::RbValue
          {% else %}
            Anyolite::RbCore::RbValue
          {% end %}
        {% end %}
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          Anyolite::Macro.resolve_type_in_ruby({{new_context}}::{{raw_type.stringify.starts_with?("::") ? raw_type.stringify[2..-1].id : raw_type}}, {{raw_type}}, {{new_context}})
        {% else %}
          Anyolite::Macro.resolve_type_in_ruby({{raw_type}}, {{raw_type}})
        {% end %}
      {% else %}
        Anyolite::RbCore::RbValue
      {% end %}
    end

    macro pointer_type(type, context = nil)
      {% if type.is_a?(TypeDeclaration) %}
        {% if type.type.is_a?(Union) %}
          Pointer(Anyolite::RbCore::RbValue)
        {% else %}
          Anyolite::Macro.pointer_type({{type.type}}, context: {{context}})
        {% end %}
      {% elsif context %}
        Anyolite::Macro.resolve_pointer_type({{context}}::{{type.stringify.starts_with?("::") ? type.stringify[2..-1].id : type}}, {{type}}, {{context}})
      {% else %}
        Anyolite::Macro.resolve_pointer_type({{type}}, {{type}})
      {% end %}
    end

    macro resolve_pointer_type(type, raw_type, context = nil)
      {% if type.resolve? %}
        {% if flag?(:use_general_object_format_chars) %}
          Pointer(Anyolite::RbCore::RbValue)
        {% else %}
          {% if type.resolve <= Bool %}
            Pointer(Anyolite::RbCore::RbBool)
          {% elsif type.resolve <= Int %}
            Pointer(Anyolite::RbCore::RbInt)
          {% elsif type.resolve <= Float || type.resolve == Number %}
            Pointer(Anyolite::RbCore::RbFloat)
          {% elsif type.resolve <= String %}
            Pointer(LibC::Char*)
          {% elsif type.resolve <= Anyolite::RbRef %}
            Pointer(Anyolite::RbCore::RbValue)
          {% elsif type.resolve <= Array %}
            Pointer(Anyolite::RbCore::RbValue)
          {% else %}
            Pointer(Anyolite::RbCore::RbValue)
          {% end %}
        {% end %}
      {% elsif context %}
        {% if context.names[0..-2].size > 0 %}
          {% new_context = context.names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          Anyolite::Macro.resolve_pointer_type({{new_context}}::{{raw_type.stringify.starts_with?("::") ? raw_type.stringify[2..-1].id : raw_type}}, {{raw_type}}, {{new_context}})
        {% else %}
          Anyolite::Macro.resolve_pointer_type({{raw_type}}, {{raw_type}})
        {% end %}
      {% else %}
        Pointer(Anyolite::RbCore::RbValue)
      {% end %}
    end
  end
end
