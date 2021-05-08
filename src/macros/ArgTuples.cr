module Anyolite
  module Macro
    macro generate_arg_tuple(rb, args, context = nil)
      Tuple.new(
        {% if args %}
          {% for arg in args %}
            {% if arg.is_a?(TypeDeclaration) %}
              {% if arg.value %}
                {% if arg.type.is_a?(Union) %}
                  # This does work, but I'm a bit surprised
                  Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::RbCast.return_value({{rb}}, {{arg.value}})),
                {% elsif arg.type.resolve <= String %}
                  # The outer gods bless my wretched soul that this does neither segfault nor leak
                  Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: {{arg.value}}.to_unsafe),
                {% elsif arg.type.resolve <= Anyolite::RbRef %}
                  Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: {{arg.value}}),
                {% elsif arg.type.resolve <= Bool %}
                  Anyolite::Macro.pointer_type({{arg}}, context: {{context}}).malloc(size: 1, value: Anyolite::Macro.type_in_ruby({{arg}}, context: {{context}}).new({{arg.value}} ? 1 : 0)),
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
  end
end