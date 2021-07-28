require "./RbCore.cr"
require "./FormatString.cr"

module Anyolite
  module Macro
    macro new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |_argc, _argv, _obj|
        _rb = Pointer(Anyolite::RbCore::State).null
        {{b.body}}
      end
    end

    macro load_args_into_vars(format_string, regular_arg_tuple, block_ptr = nil)
      {% if block_ptr %}
        Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}}, {{block_ptr}})
      {% else %}
        Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}})
      {% end %}
    end

    macro load_kw_args_into_vars(format_string, regular_arg_tuple, kw_arg_ptr, block_ptr = nil)
      kw_ptr = Pointer(RbCore::RbValue).malloc(size: 1, value: RbCast.return_nil)
      # TODO: Proper keyword handling

      {% if block_ptr %}
        Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}}, kw_ptr, {{block_ptr}})
      {% else %}
        Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}}, kw_ptr)
      {% end %}
    end
  end
end