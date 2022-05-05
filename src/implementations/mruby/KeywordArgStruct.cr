module Anyolite
  module Macro
    macro generate_keyword_argument_struct(rb_interpreter, keyword_args)
      %kw_names = Anyolite::Macro.generate_keyword_names({{rb_interpreter}}, {{keyword_args}})
      %kw_args = Anyolite::RbCore::KWArgs.new
      %kw_args.num = {{keyword_args.size}}
      %kw_args.values = Pointer(Anyolite::RbCore::RbValue).malloc(size: {{keyword_args.size}})
      %kw_args.table = %kw_names
      %kw_args.required = {{keyword_args.select { |i| !i.var }.size}}
      %kw_args.rest = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
      %kw_args
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
