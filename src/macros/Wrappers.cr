module Anyolite
  module Macro
    macro wrap_module_function_with_args(rb_interpreter, under_module, name, proc, regular_args = nil, context = nil, return_nil = nil, block_arg_number = nil, block_return_type = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        # TODO: Put these kinds of commands into a new macro
        {% if block_arg_number %}
          block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          args = Anyolite::Macro.generate_arg_tuple(rb, {{regular_args}}, context: {{context}})
          format_string = Anyolite::Macro.format_string({{regular_args}}, context: {{context}}) + "&"
          
          Anyolite::RbCore.rb_get_args(rb, format_string, *args, block_ptr)

          if Anyolite::RbCast.check_for_nil(block_ptr.value)
            Anyolite::RbCore.rb_raise_argument_error(rb, "No block given.")
            Anyolite::RbCast.return_nil
          end

          converted_args = Anyolite::Macro.convert_regular_args(rb, args, {{regular_args}}, context: {{context}})
        {% else %}
          block_ptr = nil
          converted_args = Anyolite::Macro.get_converted_args(rb, {{regular_arg_array}}, context: {{context}})
        {% end %}

        Anyolite::Macro.call_and_return(rb, {{proc}}, {{regular_arg_array}}, converted_args, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
      end

      {{rb_interpreter}}.define_module_function({{name}}, Anyolite::RbClassCache.get({{under_module}}), wrapped_method)
    end

    macro wrap_module_function_with_keyword_args(rb_interpreter, under_module, name, proc, keyword_args, regular_args = nil, operator = "", context = nil, return_nil = nil, block_arg_number = nil, block_return_type = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        regular_arg_tuple = Anyolite::Macro.generate_arg_tuple({{rb_interpreter}}, {{regular_arg_array}}, context: {{context}})

        {% if block_arg_number %}
          block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":&"
          kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
          Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args), block_ptr)

          if Anyolite::RbCast.check_for_nil(block_ptr.value)
            Anyolite::RbCore.rb_raise_argument_error(rb, "No block given.")
            Anyolite::RbCast.return_nil
          end
        {% else %}
          block_ptr = nil
          format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":"
          kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
          Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args))
        {% end %}

        converted_regular_args = Anyolite::Macro.convert_regular_args(rb, regular_arg_tuple, {{regular_arg_array}}, context: {{context}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          Anyolite::Macro.call_and_return_keyword_method(rb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, empty_regular: true, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
        {% else %}
          Anyolite::Macro.call_and_return_keyword_method(rb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
        {% end %}
      end

      {{rb_interpreter}}.define_module_function({{name}}, Anyolite::RbClassCache.get({{under_module}}), wrapped_method)
    end

    macro wrap_class_method_with_args(rb_interpreter, crystal_class, name, proc, regular_args = nil, operator = "", context = nil, return_nil = nil, block_arg_number = nil, block_return_type = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        {% if block_arg_number %}
          block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          args = Anyolite::Macro.generate_arg_tuple(rb, {{regular_args}}, context: {{context}})
          format_string = Anyolite::Macro.format_string({{regular_args}}, context: {{context}}) + "&"
          
          Anyolite::RbCore.rb_get_args(rb, format_string, *args, block_ptr)

          if Anyolite::RbCast.check_for_nil(block_ptr.value)
            Anyolite::RbCore.rb_raise_argument_error(rb, "No block given.")
            Anyolite::RbCast.return_nil
          end

          converted_args = Anyolite::Macro.convert_regular_args(rb, args, {{regular_args}}, context: {{context}})
        {% else %}
          block_ptr = nil
          converted_args = Anyolite::Macro.get_converted_args(rb, {{regular_arg_array}}, context: {{context}})
        {% end %}

        Anyolite::Macro.call_and_return(rb, {{proc}}, {{regular_arg_array}}, converted_args, operator: {{operator}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
      end
      
      {{rb_interpreter}}.define_class_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_class_method_with_keyword_args(rb_interpreter, crystal_class, name, proc, keyword_args, regular_args = nil, operator = "", context = nil, return_nil = nil, block_arg_number = nil, block_return_type = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        regular_arg_tuple = Anyolite::Macro.generate_arg_tuple({{rb_interpreter}}, {{regular_arg_array}}, context: {{context}})

        {% if block_arg_number %}
          block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":&"
          kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
          Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args), block_ptr)

          if Anyolite::RbCast.check_for_nil(block_ptr.value)
            Anyolite::RbCore.rb_raise_argument_error(rb, "No block given.")
            Anyolite::RbCast.return_nil
          end
        {% else %}
          block_ptr = nil
          format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":"
          kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
          Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args))
        {% end %}

        converted_regular_args = Anyolite::Macro.convert_regular_args(rb, regular_arg_tuple, {{regular_arg_array}}, context: {{context}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          Anyolite::Macro.call_and_return_keyword_method(rb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, 
            empty_regular: true, context: {{context}}, type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
        {% else %}
          Anyolite::Macro.call_and_return_keyword_method(rb, {{proc}}, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, 
            context: {{context}}, type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
        {% end %}
      end

      {{rb_interpreter}}.define_class_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_instance_function_with_args(rb_interpreter, crystal_class, name, proc, regular_args = nil, operator = "", context = nil, return_nil = nil, block_arg_number = nil, block_return_type = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        {% if block_arg_number %}
          block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          args = Anyolite::Macro.generate_arg_tuple(rb, {{regular_args}}, context: {{context}})
          format_string = Anyolite::Macro.format_string({{regular_args}}, context: {{context}}) + "&"
          
          Anyolite::RbCore.rb_get_args(rb, format_string, *args, block_ptr)

          if Anyolite::RbCast.check_for_nil(block_ptr.value)
            Anyolite::RbCore.rb_raise_argument_error(rb, "No block given.")
            Anyolite::RbCast.return_nil
          end

          converted_args = Anyolite::Macro.convert_regular_args(rb, args, {{regular_args}}, context: {{context}})
        {% else %}
          block_ptr = nil
          converted_args = Anyolite::Macro.get_converted_args(rb, {{regular_arg_array}}, context: {{context}})
        {% end %}

        if {{crystal_class}} <= Struct || {{crystal_class}} <= Enum
          converted_obj = Anyolite::Macro.convert_from_ruby_struct(rb, obj, {{crystal_class}}).value
        else
          converted_obj = Anyolite::Macro.convert_from_ruby_object(rb, obj, {{crystal_class}}).value
        end

        Anyolite::Macro.call_and_return_instance_method(rb, {{proc}}, converted_obj, converted_args, operator: {{operator}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
      end

      {{rb_interpreter}}.define_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_instance_function_with_keyword_args(rb_interpreter, crystal_class, name, proc, keyword_args, regular_args = nil, operator = "", context = nil, return_nil = nil, block_arg_number = nil, block_return_type = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        regular_arg_tuple = Anyolite::Macro.generate_arg_tuple({{rb_interpreter}}, {{regular_arg_array}}, context: {{context}})

        # TODO: Add annotation argument for required blocks ('&!' then)

        {% if block_arg_number %}
          block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":&"
          kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
          Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args), block_ptr)

          if Anyolite::RbCast.check_for_nil(block_ptr.value)
            Anyolite::RbCore.rb_raise_argument_error(rb, "No block given.")
            Anyolite::RbCast.return_nil
          end
        {% else %}
          block_ptr = nil
          format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":"
          kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
          Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args))
        {% end %}

        converted_regular_args = Anyolite::Macro.convert_regular_args(rb, regular_arg_tuple, {{regular_arg_array}}, context: {{context}})

        if {{crystal_class}} <= Struct || {{crystal_class}} <= Enum
          converted_obj = Anyolite::Macro.convert_from_ruby_struct(rb, obj, {{crystal_class}}).value
        else
          converted_obj = Anyolite::Macro.convert_from_ruby_object(rb, obj, {{crystal_class}}).value
        end

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          Anyolite::Macro.call_and_return_keyword_instance_method(rb, {{proc}}, converted_obj, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, 
            empty_regular: true, context: {{context}}, type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
        {% else %}
          Anyolite::Macro.call_and_return_keyword_instance_method(rb, {{proc}}, converted_obj, converted_regular_args, {{keyword_args}}, kw_args, operator: {{operator}}, 
            context: {{context}}, type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, block_ptr: block_ptr)
        {% end %}
      end

      {{rb_interpreter}}.define_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_constructor_function_with_args(rb_interpreter, crystal_class, proc, regular_args = nil, operator = "", context = nil, block_arg_number = nil, block_return_type = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% if !block_arg_number %}
        {% proc_arg_string = "" %}
      {% elsif block_arg_number == 0 %}
        {% proc_arg_string = "do" %}
      {% else %}
        {% proc_arg_string = "do |" + (0..block_arg_number-1).map{|x| "block_arg_#{x}"}.join(", ") + "|" %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}

      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        {% if block_arg_number %}
          block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          args = Anyolite::Macro.generate_arg_tuple(rb, {{regular_args}}, context: {{context}})
          format_string = Anyolite::Macro.format_string({{regular_args}}, context: {{context}}) + "&"
          
          Anyolite::RbCore.rb_get_args(rb, format_string, *args, block_ptr)

          if Anyolite::RbCast.check_for_nil(block_ptr.value)
            Anyolite::RbCore.rb_raise_argument_error(rb, "No block given.")
            Anyolite::RbCast.return_nil
          end

          converted_args = Anyolite::Macro.convert_regular_args(rb, args, {{regular_args}}, context: {{context}})
        {% else %}
          block_ptr = nil
          converted_args = Anyolite::Macro.get_converted_args(rb, {{regular_arg_array}}, context: {{context}})
        {% end %}

        new_obj = {{proc}}{{operator.id}}(*converted_args) {{proc_arg_string.id}}

        {% if block_arg_number == 0 %}
            yield_value = Anyolite::RbCore.rb_yield({{rb}}, {{block_ptr}}.value, Anyolite::RbCast.return_nil)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, yield_value, {{block_return_type}})
          end
        {% elsif block_arg_number %}
            block_arg_array = [
              {% for i in 0..block_arg_number-1 %}
                Anyolite::RbCast.return_value({{rb}}, {{"block_arg_#{i}".id}}),
              {% end %}
            ]
            yield_value = Anyolite::RbCore.rb_yield_argv({{rb}}, {{block_ptr}}.value, {{block_arg_number}}, block_arg_array)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, yield_value, {{block_return_type}})
          end
        {% end %}

        Anyolite::Macro.allocate_constructed_object({{crystal_class}}, obj, new_obj)
        obj
      end

      {{rb_interpreter}}.define_method("initialize", Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_constructor_function_with_keyword_args(rb_interpreter, crystal_class, proc, keyword_args, regular_args = nil, operator = "", context = nil, block_arg_number = nil, block_return_type = nil)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% if !block_arg_number %}
        {% proc_arg_string = "" %}
      {% elsif block_arg_number == 0 %}
        {% proc_arg_string = "do" %}
      {% else %}
        {% proc_arg_string = "do |" + (0..block_arg_number-1).map{|x| "block_arg_#{x}"}.join(", ") + "|" %}
      {% end %}

      {% type_vars = crystal_class.resolve.type_vars %}
      {% type_var_names_annotation = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% type_var_names = type_var_names_annotation ? type_var_names_annotation[0] : nil %}
      
      wrapped_method = Anyolite::RbCore::RbFunc.new do |rb, obj|
        regular_arg_tuple = Anyolite::Macro.generate_arg_tuple({{rb_interpreter}}, {{regular_arg_array}}, context: {{context}})

        {% if block_arg_number %}
          block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":&"
          kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
          Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args), block_ptr)

          if Anyolite::RbCast.check_for_nil(block_ptr.value)
            Anyolite::RbCore.rb_raise_argument_error(rb, "No block given.")
            Anyolite::RbCast.return_nil
          end
        {% else %}
          block_ptr = nil
          format_string = Anyolite::Macro.format_string({{regular_arg_array}}, context: {{context}}) + ":"
          kw_args = Anyolite::Macro.generate_keyword_argument_struct({{rb_interpreter}}, {{keyword_args}})
          Anyolite::RbCore.rb_get_args(rb, format_string, *regular_arg_tuple, pointerof(kw_args))
        {% end %}

        converted_regular_args = Anyolite::Macro.convert_regular_args(rb, regular_arg_tuple, {{regular_arg_array}}, context: {{context}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          new_obj = {{proc}}{{operator.id}}(
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal(rb, kw_args.values[{{c}}], {{keyword}}, context: {{context}}, 
                type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          ) {{proc_arg_string.id}}
        {% else %}
          new_obj = {{proc}}{{operator.id}}(*converted_regular_args,
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal(rb, kw_args.values[{{c}}], {{keyword}}, context: {{context}}, 
                type_vars: {{type_vars}}, type_var_names: {{type_var_names}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          ) {{proc_arg_string.id}}
        {% end %}

        {% if block_arg_number == 0 %}
            yield_value = Anyolite::RbCore.rb_yield({{rb}}, {{block_ptr}}.value, Anyolite::RbCast.return_nil)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, yield_value, {{block_return_type}})
          end
        {% elsif block_arg_number %}
            block_arg_array = [
              {% for i in 0..block_arg_number-1 %}
                Anyolite::RbCast.return_value({{rb}}, {{"block_arg_#{i}".id}}),
              {% end %}
            ]
            yield_value = Anyolite::RbCore.rb_yield_argv({{rb}}, {{block_ptr}}.value, {{block_arg_number}}, block_arg_array)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, yield_value, {{block_return_type}})
          end
        {% end %}

        Anyolite::Macro.allocate_constructed_object({{crystal_class}}, obj, new_obj)
        obj
      end

      {{rb_interpreter}}.define_method("initialize", Anyolite::RbClassCache.get({{crystal_class}}), wrapped_method)
    end

    macro wrap_constant_or_class(rb_interpreter, under_class_or_module, ruby_name, value, overwrite = false, verbose = false)
      {% actual_constant = under_class_or_module.resolve.constant(value.id) %}
      {% if actual_constant.is_a?(TypeNode) %}
        {% if actual_constant.module? %}
          Anyolite.wrap_module_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, overwrite: {{overwrite}}, verbose: {{verbose}})
        {% elsif actual_constant.class? || actual_constant.struct? %}
          Anyolite.wrap_class_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, overwrite: {{overwrite}}, verbose: {{verbose}})
        {% elsif actual_constant.union? %}
          {% puts "\e[31m> WARNING: Wrapping of unions not supported, thus skipping #{actual_constant}\e[0m" %}
        {% elsif actual_constant < Enum %}
          Anyolite.wrap_class_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, use_enum_constructor: true, overwrite: {{overwrite}}, verbose: {{verbose}})
        {% else %}
          # Could be an alias, just try the default case
          Anyolite.wrap_class_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, overwrite: {{overwrite}}, verbose: {{verbose}})
        {% end %}
      {% else %}
        Anyolite.wrap_constant_under_class({{rb_interpreter}}, {{under_class_or_module}}, {{ruby_name}}, {{under_class_or_module}}::{{value}})
      {% end %}
    end
  end
end