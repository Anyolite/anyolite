{% unless flag?(:anyolite_implementation_ruby_3) %}
  {% skip_file %}
{% end %}

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
      Anyolite::RbCore::RbDataFunc.new do |__ptr|
        __rb = Pointer(Anyolite::RbCore::State).null
        {{b.body}}
      end
    end

    macro set_default_args_for_regular_args(args, regular_arg_tuple, number_of_args)
      {% c = 0 %}
      {% if args %}
        {% for arg in args %}
          {% if arg.is_a? TypeDeclaration %}
            {% if arg.value %}
              if {{number_of_args}} <= {{c}} && Anyolite::RbCast.check_for_nil({{regular_arg_tuple}}[{{c}}].value)
                {{regular_arg_tuple}}[{{c}}].value = Anyolite::RbCast.return_value(_rb, {{arg.value}})
              end
            {% end %}
          {% elsif arg.is_a? Path %}
            # No default argument was given, so no action is required here
          {% else %}
            {% raise "Not a TypeDeclaration or a Path: #{arg} of #{arg.class_name}" %}
          {% end %}
          {% c += 1 %}
        {% end %}
      {% end %}
    end

    macro load_args_into_vars(args, format_string, regular_arg_tuple, block_ptr = nil)
      {% if block_ptr %}
        %number_of_args = Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}}, {{block_ptr}})
      {% else %}
        %number_of_args = Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}})
      {% end %}

      Anyolite::Macro.set_default_args_for_regular_args({{args}}, {{regular_arg_tuple}}, %number_of_args)
    end

    macro load_kw_args_into_vars(regular_args, keyword_args, format_string, regular_arg_tuple, block_ptr = nil)
      %kw_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1, value: Anyolite::RbCast.return_nil)

      {% if block_ptr %}
        %number_of_args = Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}}, %kw_ptr, {{block_ptr}})
      {% else %}
        %number_of_args = Anyolite::RbCore.rb_get_args(_argc, _argv, {{format_string}}, *{{regular_arg_tuple}}, %kw_ptr)
      {% end %}

      # TODO: Is number_of_args for the regular arg function correct here?

      Anyolite::Macro.set_default_args_for_regular_args({{regular_args}}, {{regular_arg_tuple}}, %number_of_args)

      # TODO: This is relatively complicated and messy, so can this be simplified?

      if Anyolite::RbCast.check_for_nil(%kw_ptr.value)
        %hash_key_values = [] of String
      else
        %rb_hash_key_values = Anyolite::RbCore.rb_hash_keys(_rb, %kw_ptr.value)
        %hash_key_values = Anyolite::Macro.convert_from_ruby_to_crystal(_rb, %rb_hash_key_values, k : Array(String))
      end

      %return_hash = {} of Symbol => Anyolite::RbCore::RbValue
      {% for keyword_arg in keyword_args %}
        {% if keyword_arg.is_a? TypeDeclaration %}
          if %hash_key_values.includes?(":{{keyword_arg.var.id}}")
            %ruby_hash_value = Anyolite::RbCore.rb_hash_get(_rb, %kw_ptr.value, Anyolite::RbCore.get_symbol_value_of_string(_rb, "{{keyword_arg.var.id}}"))
            %return_hash[:{{keyword_arg.var.id}}] = %ruby_hash_value
          else
            {% if !keyword_arg.value.is_a? Nop %}
              %return_hash[:{{keyword_arg.var.id}}] = Anyolite::RbCast.return_value(_rb, {{keyword_arg.value}})
            {% else %}
              Anyolite.raise_argument_error("Keyword #{"{{keyword_arg.var.id}}"} was not defined.")
            {% end %}
          end
        {% elsif arg.is_a? Path %}
          # No default argument was given, so no action is required here
        {% else %}
          {% raise "Not a TypeDeclaration or a Path: #{keyword_arg} of #{keyword_arg.class_name}" %}
        {% end %}
      {% end %}

      %return_hash
    end
  end
end
