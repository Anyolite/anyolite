require "./RbCore.cr"
require "./FormatString.cr"

module Anyolite
  module Macro
    macro new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |_rb, _obj|
        {{b.body}}
      end
    end

    macro new_rb_data_func(&b)
      Anyolite::RbCore::RbDataFunc.new do |__rb, __ptr|
        {{b.body}}
      end
    end

    macro load_args_into_vars(format_string, regular_arg_tuple, block_ptr = nil)
      {% if block_ptr %}
        Anyolite::RbCore.rb_get_args(_rb, {{format_string}}, *{{regular_arg_tuple}}, {{block_ptr}})
      {% else %}
        Anyolite::RbCore.rb_get_args(_rb, {{format_string}}, *{{regular_arg_tuple}})
      {% end %}
    end

    macro load_kw_args_into_vars(format_string, regular_arg_tuple, kw_arg_ptr, block_ptr = nil)
      {% if block_ptr %}
        Anyolite::RbCore.rb_get_args(_rb, {{format_string}}, *{{regular_arg_tuple}}, {{kw_arg_ptr}}, {{block_ptr}})
      {% else %}
        Anyolite::RbCore.rb_get_args(_rb, {{format_string}}, *{{regular_arg_tuple}}, {{kw_arg_ptr}})
      {% end %}
    end
  end
end