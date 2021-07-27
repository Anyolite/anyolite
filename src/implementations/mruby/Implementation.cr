require "./RbCore.cr"
require "./FormatString.cr"

module Anyolite
  module Macro
    macro new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |rb, obj|
        {{b.body}}
      end
    end

    macro load_args_into_vars(rb, format_string, regular_arg_tuple, block_ptr = nil)
      {% if block_ptr %}
        Anyolite::RbCore.rb_get_args({{rb}}, {{format_string}}, *{{regular_arg_tuple}}, {{block_ptr}})
      {% else %}
        Anyolite::RbCore.rb_get_args({{rb}}, {{format_string}}, *{{regular_arg_tuple}})
      {% end %}
    end

    macro load_kw_args_into_vars(rb, format_string, regular_arg_tuple, kw_arg_ptr, block_ptr = nil)
      {% if block_ptr %}
        Anyolite::RbCore.rb_get_args({{rb}}, {{format_string}}, *{{regular_arg_tuple}}, {{kw_arg_ptr}}, {{block_ptr}})
      {% else %}
        Anyolite::RbCore.rb_get_args({{rb}}, {{format_string}}, *{{regular_arg_tuple}}, {{kw_arg_ptr}})
      {% end %}
    end
  end
end