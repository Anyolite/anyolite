require "./RbCore.cr"
require "./FormatString.cr"
require "./KeywordArgStruct.cr"

{% if flag?(:use_general_object_format_chars) %}
  ANYOLITE_INTERNAL_FLAG_USE_GENERAL_OBJECT_FORMAT_CHARS = true
{% end %}

module Anyolite
  module Macro
    macro new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |_rb, _obj|
        begin
          {{b.body}}
        rescue ex : ArgumentError
          Anyolite.raise_argument_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex : DivisionByZeroError
          Anyolite.raise_runtime_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex : IndexError
          Anyolite.raise_index_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex : KeyError
          Anyolite.raise_key_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex : NilAssertionError
          Anyolite.raise_runtime_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex : NotImplementedError
          Anyolite.raise_not_implemented_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex : OverflowError
          Anyolite.raise_runtime_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex : RuntimeError
          Anyolite.raise_runtime_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex : TypeCastError
          Anyolite.raise_type_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        rescue ex
          Anyolite.raise_runtime_error("#{ex.inspect_with_backtrace} (raised from Crystal)")
          Anyolite::RbCast.return_nil
        end
      end
    end

    macro new_rb_data_func(&b)
      Anyolite::RbCore::RbDataFunc.new do |__rb, __ptr|
        {{b.body}}
      end
    end

    macro convert_regex_from_ruby_to_crystal(rb, arg, arg_type)
      Anyolite::Macro.convert_from_ruby_object({{rb}}, {{arg}}, {{arg_type}}).value
    end

    macro convert_regex_from_crystal_to_ruby(rb, value)
      RbCast.return_object({{rb}}, {{value}})
    end

    macro load_args_into_vars(args, format_string, regular_arg_tuple, block_ptr = nil)
      {% if block_ptr %}
        Anyolite::RbCore.rb_get_args(_rb, {{format_string}}, *{{regular_arg_tuple}}, {{block_ptr}})
      {% else %}
        Anyolite::RbCore.rb_get_args(_rb, {{format_string}}, *{{regular_arg_tuple}})
      {% end %}
    end

    macro load_kw_args_into_vars(regular_args, keyword_args, format_string, regular_arg_tuple, block_ptr = nil)
      %kw_args = Anyolite::Macro.generate_keyword_argument_struct(_rb, {{keyword_args}})

      {% if block_ptr %}
        Anyolite::RbCore.rb_get_args(_rb, {{format_string}}, *{{regular_arg_tuple}}, pointerof(%kw_args), {{block_ptr}})
      {% else %}
        Anyolite::RbCore.rb_get_args(_rb, {{format_string}}, *{{regular_arg_tuple}}, pointerof(%kw_args))
      {% end %}

      %kw_args
    end
  end
end
