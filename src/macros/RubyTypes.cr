module Anyolite
  module Macro
    macro type_in_ruby(type, options = {} of Symbol => NoReturn)
      {% if type.is_a?(TypeDeclaration) %}
        {% if type.type.is_a?(Union) %}
          Anyolite::RbCore::RbValue
        {% else %}
          Anyolite::Macro.type_in_ruby({{type.type}})
        {% end %}
      {% elsif options[:context] %}
        Anyolite::Macro.resolve_type_in_ruby({{options[:context]}}::{{type.stringify.starts_with?("::") ? type.stringify[2..-1].id : type}}, {{type}}, options: {{options}})
      {% else %}
        Anyolite::Macro.resolve_type_in_ruby({{type}}, {{type}})
      {% end %}
    end

    macro resolve_type_in_ruby(type, raw_type, options = {} of Symbol => NoReturn)
      {% if type.resolve? %}
        {% if ANYOLITE_INTERNAL_FLAG_USE_GENERAL_OBJECT_FORMAT_CHARS %}
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
          {% elsif type.resolve <= Regex %}
            Anyolite::RbCore::RbValue
          {% elsif type.resolve <= Array %}
            Anyolite::RbCore::RbValue
          {% else %}
            Anyolite::RbCore::RbValue
          {% end %}
        {% end %}
      {% elsif options[:context] %}
        {% if options[:context].names[0..-2].size > 0 %}
          {% new_context = options[:context].names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          {% options[:context] = new_context %}
          Anyolite::Macro.resolve_type_in_ruby({{new_context}}::{{raw_type.stringify.starts_with?("::") ? raw_type.stringify[2..-1].id : raw_type}}, {{raw_type}}, options: {{options}})
        {% else %}
          Anyolite::Macro.resolve_type_in_ruby({{raw_type}}, {{raw_type}})
        {% end %}
      {% else %}
        Anyolite::RbCore::RbValue
      {% end %}
    end

    macro pointer_type(type, options = {} of Symbol => NoReturn)
      {% if type.is_a?(TypeDeclaration) %}
        {% if type.type.is_a?(Union) %}
          Pointer(Anyolite::RbCore::RbValue)
        {% else %}
          Anyolite::Macro.pointer_type({{type.type}}, options: {{options}})
        {% end %}
      {% elsif options[:context] %}
        Anyolite::Macro.resolve_pointer_type({{options[:context]}}::{{type.stringify.starts_with?("::") ? type.stringify[2..-1].id : type}}, {{type}}, options: {{options}})
      {% else %}
        Anyolite::Macro.resolve_pointer_type({{type}}, {{type}})
      {% end %}
    end

    macro resolve_pointer_type(type, raw_type, options = {} of Symbol => NoReturn)
      {% if type.resolve? %}
        {% if ANYOLITE_INTERNAL_FLAG_USE_GENERAL_OBJECT_FORMAT_CHARS %}
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
      {% elsif options[:context] %}
        {% if options[:context].names[0..-2].size > 0 %}
          {% new_context = options[:context].names[0..-2].join("::").gsub(/(\:\:)+/, "::").id %}
          {% options[:context] = new_context %}
          Anyolite::Macro.resolve_pointer_type({{new_context}}::{{raw_type.stringify.starts_with?("::") ? raw_type.stringify[2..-1].id : raw_type}}, {{raw_type}}, options: {{options}})
        {% else %}
          Anyolite::Macro.resolve_pointer_type({{raw_type}}, {{raw_type}})
        {% end %}
      {% else %}
        Pointer(Anyolite::RbCore::RbValue)
      {% end %}
    end
  end
end
