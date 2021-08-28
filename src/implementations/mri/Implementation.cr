require "./RbCore.cr"
require "./FormatString.cr"

{% if !flag?(:use_general_object_format_chars) %}
  {% raise "Flag 'use_general_object_format_chars' needs to be set for a working MRI implementation" %}
{% end %}

module Anyolite
  module Macro
    macro new_rb_func(&b)
      Anyolite::RbCore::RbFunc.new do |_argc, _argv, _obj|
        _rb = Pointer(Anyolite::RbCore::State).null
        {{b.body}}
      end
    end

    macro new_rb_data_func(&b)
      Anyolite::RbCore::RbDataFunc.new do |__ptr|
        __rb = Pointer(Anyolite::RbCore::State).null
        {{b.body}}
      end
    end

    macro load_args_into_vars(args, format_string, regular_arg_tuple, block_ptr = nil)
      {% if block_ptr %}
        number_of_args = Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}}, {{block_ptr}})
      {% else %}
        number_of_args = Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}})
      {% end %}

      {% c = 0 %}
      {% for arg in args %}
        {% if arg.is_a? TypeDeclaration %}
          {% if arg.value %}
            if number_of_args <= {{c}} && Anyolite::RbCast.check_for_nil({{regular_arg_tuple}}[{{c}}].value)
              {{regular_arg_tuple}}[{{c}}].value = Anyolite::RbCast.return_value(_rb, {{arg.value}})
            end
          {% end %}
        {% else %}
          {% raise "Not a TypeDeclaration: #{arg} of #{arg.class_name}" %}
        {% end %}
        {% c += 1 %}
      {% end %}

      # TODO: Block args
      # TODO: Default arguments
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