module Anyolite
  module Macro
    macro wrap_module_function_with_args(rb_interpreter, under_module, name, proc, regular_args = nil, operator = "", options = {} of Symbol => NoReturn)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% options[:type_vars] = under_module.resolve.type_vars %}
      {% options[:type_var_names_annotation] = under_module.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}

      %wrapped_method = Anyolite::Macro.new_rb_func do
        # TODO: Put these kinds of commands into a new macro
        {% if options[:block_arg_number] || options[:store_block_arg] %}
          %block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)
          
          {% if options[:store_block_arg] %}
            Anyolite::RbArgCache.set_block_cache(%block_ptr)
          {% end %}

          %args = Anyolite::Macro.generate_arg_tuple(_rb, {{regular_args}}, options: {{options}})
          %format_string = Anyolite::Macro.format_string({{regular_args}}, options: {{options}}) + "&"
          
          Anyolite::Macro.load_args_into_vars({{regular_args}}, %format_string, %args, %block_ptr)

          {% if options[:block_arg_number] %}
            if Anyolite::RbCast.check_for_nil(%block_ptr.value)
              Anyolite.raise_argument_error("No block given.")
              Anyolite::RbCast.return_nil
            end
          {% end %}

          %converted_args = Anyolite::Macro.convert_regular_args(_rb, %args, {{regular_args}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})
        {% else %}
          %block_ptr = nil
          %converted_args = Anyolite::Macro.get_converted_args(_rb, {{regular_arg_array}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})
        {% end %}

        %return_value = Anyolite::Macro.call_and_return(_rb, {{proc}}, {{regular_arg_array}}, %converted_args, operator: {{operator}}, options: {{options}}, block_ptr: %block_ptr)

        {% if options[:store_block_arg] %}
          Anyolite::RbArgCache.reset_block_cache
        {% end %}

        %return_value
      end

      {{rb_interpreter}}.define_module_function({{name}}, Anyolite::RbClassCache.get({{under_module}}), %wrapped_method)
    end

    macro wrap_module_function_with_keyword_args(rb_interpreter, under_module, name, proc, keyword_args, regular_args = nil, operator = "", options = {} of Symbol => NoReturn)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% options[:type_vars] = under_module.resolve.type_vars %}
      {% options[:type_var_names_annotation] = under_module.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}

      %wrapped_method = Anyolite::Macro.new_rb_func do
        %regular_arg_tuple = Anyolite::Macro.generate_arg_tuple(_rb, {{regular_arg_array}}, options: {{options}})

        {% if options[:block_arg_number] || options[:store_block_arg] %}
          %block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)

          {% if options[:store_block_arg] %}
            Anyolite::RbArgCache.set_block_cache(%block_ptr)
          {% end %}

          %format_string = Anyolite::Macro.format_string({{regular_arg_array}}, options: {{options}}) + ":&"
          %kw_args = Anyolite::Macro.load_kw_args_into_vars({{regular_arg_array}}, {{keyword_args}}, %format_string, %regular_arg_tuple, %block_ptr)

          {% if options[:block_arg_number] %}
            if Anyolite::RbCast.check_for_nil(%block_ptr.value)
              Anyolite.raise_argument_error("No block given.")
              Anyolite::RbCast.return_nil
            end
          {% end %}
        {% else %}
          %block_ptr = nil
          %format_string = Anyolite::Macro.format_string({{regular_arg_array}}, options: {{options}}) + ":"
          %kw_args = Anyolite::Macro.load_kw_args_into_vars({{regular_arg_array}}, {{keyword_args}}, %format_string, %regular_arg_tuple)
        {% end %}

        %converted_regular_args = Anyolite::Macro.convert_regular_args(_rb, %regular_arg_tuple, {{regular_arg_array}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          {% options[:empty_regular] = true %}
        {% end %}

        %return_value = Anyolite::Macro.call_and_return_keyword_method(_rb, {{proc}}, %converted_regular_args, {{keyword_args}}, %kw_args, operator: {{operator}}, options: {{options}}, block_ptr: %block_ptr)
        
        {% if options[:store_block_arg] %}
          Anyolite::RbArgCache.reset_block_cache
        {% end %}

        %return_value
      end

      {{rb_interpreter}}.define_module_function({{name}}, Anyolite::RbClassCache.get({{under_module}}), %wrapped_method)
    end

    macro wrap_class_method_with_args(rb_interpreter, crystal_class, name, proc, regular_args = nil, operator = "", options = {} of Symbol => NoReturn)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% options[:type_vars] = crystal_class.resolve.type_vars %}
      {% options[:type_var_names_annotation] = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}

      %wrapped_method = Anyolite::Macro.new_rb_func do
        {% if options[:block_arg_number] || options[:store_block_arg] %}
          %block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)

          {% if options[:store_block_arg] %}
            Anyolite::RbArgCache.set_block_cache(%block_ptr)
          {% end %}

          %args = Anyolite::Macro.generate_arg_tuple(_rb, {{regular_args}}, options: {{options}})
          %format_string = Anyolite::Macro.format_string({{regular_args}}, options: {{options}}) + "&"

          Anyolite::Macro.load_args_into_vars({{regular_args}}, %format_string, %args, %block_ptr)

          {% if options[:block_arg_number] %}
            if Anyolite::RbCast.check_for_nil(%block_ptr.value)
              Anyolite.raise_argument_error("No block given.")
              Anyolite::RbCast.return_nil
            end
          {% end %}

          %converted_args = Anyolite::Macro.convert_regular_args(_rb, %args, {{regular_args}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})
        {% else %}
          %block_ptr = nil
          %converted_args = Anyolite::Macro.get_converted_args(_rb, {{regular_arg_array}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})
        {% end %}

        %return_value = Anyolite::Macro.call_and_return(_rb, {{proc}}, {{regular_arg_array}}, %converted_args, operator: {{operator}}, options: {{options}}, block_ptr: %block_ptr)

        {% if options[:store_block_arg] %}
          Anyolite::RbArgCache.reset_block_cache
        {% end %}

        %return_value
      end
      
      {{rb_interpreter}}.define_class_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), %wrapped_method)
    end

    macro wrap_class_method_with_keyword_args(rb_interpreter, crystal_class, name, proc, keyword_args, regular_args = nil, operator = "", options = {} of Symbol => NoReturn)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% options[:type_vars] = crystal_class.resolve.type_vars %}
      {% options[:type_var_names_annotation] = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}

      %wrapped_method = Anyolite::Macro.new_rb_func do
        %regular_arg_tuple = Anyolite::Macro.generate_arg_tuple(_rb, {{regular_arg_array}}, options: {{options}})

        {% if options[:block_arg_number] || options[:store_block_arg] %}
          %block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)

          {% if options[:store_block_arg] %}
            Anyolite::RbArgCache.set_block_cache(%block_ptr)
          {% end %}

          %format_string = Anyolite::Macro.format_string({{regular_arg_array}}, options: {{options}}) + ":&"
          %kw_args = Anyolite::Macro.load_kw_args_into_vars({{regular_arg_array}}, {{keyword_args}}, %format_string, %regular_arg_tuple, %block_ptr)

          {% if options[:block_arg_number] %}
            if Anyolite::RbCast.check_for_nil(%block_ptr.value)
              Anyolite.raise_argument_error("No block given.")
              Anyolite::RbCast.return_nil
            end
          {% end %}
        {% else %}
          %block_ptr = nil
          %format_string = Anyolite::Macro.format_string({{regular_arg_array}}, options: {{options}}) + ":"
          %kw_args = Anyolite::Macro.load_kw_args_into_vars({{regular_arg_array}}, {{keyword_args}}, %format_string, %regular_arg_tuple)
        {% end %}

        %converted_regular_args = Anyolite::Macro.convert_regular_args(_rb, %regular_arg_tuple, {{regular_arg_array}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          {% options[:empty_regular] = true %}
        {% end %}

        %return_value = Anyolite::Macro.call_and_return_keyword_method(_rb, {{proc}}, %converted_regular_args, {{keyword_args}}, %kw_args, operator: {{operator}}, options: {{options}}, block_ptr: %block_ptr)

        {% if options[:store_block_arg] %}
          Anyolite::RbArgCache.reset_block_cache
        {% end %}

        %return_value
      end

      {{rb_interpreter}}.define_class_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), %wrapped_method)
    end

    macro wrap_instance_function_with_args(rb_interpreter, crystal_class, name, proc, regular_args = nil, operator = "", options = {} of Symbol => NoReturn)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% options[:type_vars] = crystal_class.resolve.type_vars %}
      {% options[:type_var_names_annotation] = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}

      %wrapped_method = Anyolite::Macro.new_rb_func do
        {% if options[:block_arg_number] || options[:store_block_arg] %}
          %block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)

          {% if options[:store_block_arg] %}
            Anyolite::RbArgCache.set_block_cache(%block_ptr)
          {% end %}

          %args = Anyolite::Macro.generate_arg_tuple(_rb, {{regular_args}}, options: {{options}})
          %format_string = Anyolite::Macro.format_string({{regular_args}}, options: {{options}}) + "&"
          
          Anyolite::Macro.load_args_into_vars({{regular_args}}, %format_string, %args, %block_ptr)

          {% if options[:block_arg_number] %}
            if Anyolite::RbCast.check_for_nil(%block_ptr.value)
              Anyolite.raise_argument_error("No block given.")
              Anyolite::RbCast.return_nil
            end
          {% end %}

          %converted_args = Anyolite::Macro.convert_regular_args(_rb, %args, {{regular_args}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})
        {% else %}
          %block_ptr = nil
          %converted_args = Anyolite::Macro.get_converted_args(_rb, {{regular_arg_array}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})
        {% end %}

        if {{crystal_class}} <= Struct || {{crystal_class}} <= Enum
          %converted_obj = Anyolite::Macro.convert_from_ruby_struct(_rb, _obj, {{crystal_class}}).value
        else
          %converted_obj = Anyolite::Macro.convert_from_ruby_object(_rb, _obj, {{crystal_class}}).value
        end

        %return_value = Anyolite::Macro.call_and_return_instance_method(_rb, {{proc}}, %converted_obj, %converted_args, operator: {{operator}}, options: {{options}}, block_ptr: %block_ptr)
        
        {% if options[:store_block_arg] %}
          Anyolite::RbArgCache.reset_block_cache
        {% end %}

        %return_value
      end

      {{rb_interpreter}}.define_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), %wrapped_method)
    end

    macro wrap_instance_function_with_keyword_args(rb_interpreter, crystal_class, name, proc, keyword_args, regular_args = nil, operator = "", options = {} of Symbol => NoReturn)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% options[:type_vars] = crystal_class.resolve.type_vars %}
      {% options[:type_var_names_annotation] = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}

      %wrapped_method = Anyolite::Macro.new_rb_func do
        %regular_arg_tuple = Anyolite::Macro.generate_arg_tuple(_rb, {{regular_arg_array}}, options: {{options}})

        # TODO: Add annotation argument for required blocks ('&!' then)

        {% if options[:block_arg_number] || options[:store_block_arg] %}
          %block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)

          {% if options[:store_block_arg] %}
            Anyolite::RbArgCache.set_block_cache(%block_ptr)
          {% end %}

          %format_string = Anyolite::Macro.format_string({{regular_arg_array}}, options: {{options}}) + ":&"
          %kw_args = Anyolite::Macro.load_kw_args_into_vars({{regular_arg_array}}, {{keyword_args}}, %format_string, %regular_arg_tuple, %block_ptr)

          {% if options[:block_arg_number] %}
            if Anyolite::RbCast.check_for_nil(%block_ptr.value)
              Anyolite.raise_argument_error("No block given.")
              Anyolite::RbCast.return_nil
            end
          {% end %}
        {% else %}
          %block_ptr = nil
          %format_string = Anyolite::Macro.format_string({{regular_arg_array}}, options: {{options}}) + ":"
          %kw_args = Anyolite::Macro.load_kw_args_into_vars({{regular_arg_array}}, {{keyword_args}}, %format_string, %regular_arg_tuple)
        {% end %}

        %converted_regular_args = Anyolite::Macro.convert_regular_args(_rb, %regular_arg_tuple, {{regular_arg_array}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})

        if {{crystal_class}} <= Struct || {{crystal_class}} <= Enum
          %converted_obj = Anyolite::Macro.convert_from_ruby_struct(_rb, _obj, {{crystal_class}}).value
        else
          %converted_obj = Anyolite::Macro.convert_from_ruby_object(_rb, _obj, {{crystal_class}}).value
        end

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          {% options[:empty_regular] = true %}
        {% end %}

        %return_value = Anyolite::Macro.call_and_return_keyword_instance_method(_rb, {{proc}}, %converted_obj, %converted_regular_args, {{keyword_args}}, %kw_args, operator: {{operator}}, options: {{options}}, block_ptr: %block_ptr)

        {% if options[:store_block_arg] %}
          Anyolite::RbArgCache.reset_block_cache
        {% end %}

        %return_value
      end

      {{rb_interpreter}}.define_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), %wrapped_method)
    end

    macro wrap_constructor_function_with_args(rb_interpreter, crystal_class, proc, regular_args = nil, operator = "", options = {} of Symbol => NoReturn)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% if !options[:block_arg_number] %}
        {% proc_arg_string = "" %}
      {% elsif options[:block_arg_number] == 0 %}
        {% proc_arg_string = "do" %}
      {% else %}
        {% proc_arg_string = "do |" + (0..options[:block_arg_number] - 1).map { |x| "block_arg_#{x}" }.join(", ") + "|" %}
      {% end %}

      {% options[:type_vars] = crystal_class.resolve.type_vars %}
      {% options[:type_var_names_annotation] = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}

      %wrapped_method = Anyolite::Macro.new_rb_func do
        {% if options[:block_arg_number] || options[:store_block_arg] %}
          %block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)

          {% if options[:store_block_arg] %}
            Anyolite::RbArgCache.set_block_cache(%block_ptr)
          {% end %}

          %args = Anyolite::Macro.generate_arg_tuple(_rb, {{regular_args}}, options: {{options}})
          %format_string = Anyolite::Macro.format_string({{regular_args}}, options: {{options}}) + "&"

          Anyolite::Macro.load_args_into_vars({{regular_args}}, %format_string, %args, %block_ptr)

          {% if options[:block_arg_number] %}
            if Anyolite::RbCast.check_for_nil(%block_ptr.value)
              Anyolite.raise_argument_error("No block given.")
              Anyolite::RbCast.return_nil
            end
          {% end %}

          %converted_args = Anyolite::Macro.convert_regular_args(_rb, %args, {{regular_args}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})
        {% else %}
          %block_ptr = nil
          %converted_args = Anyolite::Macro.get_converted_args(_rb, {{regular_arg_array}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})
        {% end %}

        %new_obj = {{proc}}{{operator.id}}(*%converted_args) {{proc_arg_string.id}}

        {% if options[:block_arg_number] == 0 %}
            %yield_value = Anyolite::RbCore.rb_yield(_rb, %block_ptr.value, Anyolite::RbCast.return_nil)
            Anyolite::Macro.convert_from_ruby_to_crystal(_rb, %yield_value, {{options[:block_return_type]}})
          end
        {% elsif options[:block_arg_number] %}
            %block_arg_array = [
              {% for i in 0..options[:block_arg_number] - 1 %}
                Anyolite::RbCast.return_value(_rb, {{"block_arg_#{i}".id}}),
              {% end %}
            ]
            %yield_value = Anyolite::RbCore.rb_yield_argv(_rb, %block_ptr.value, {{options[:block_arg_number]}}, %block_arg_array)
            Anyolite::Macro.convert_from_ruby_to_crystal(_rb, %yield_value, {{options[:block_return_type]}})
          end
        {% end %}

        Anyolite::Macro.allocate_constructed_object(_rb, {{crystal_class}}, _obj, %new_obj)

        {% if options[:store_block_arg] %}
          Anyolite::RbArgCache.reset_block_cache
        {% end %}

        _obj
      end

      {{rb_interpreter}}.define_method("initialize", Anyolite::RbClassCache.get({{crystal_class}}), %wrapped_method)
    end

    macro wrap_constructor_function_with_keyword_args(rb_interpreter, crystal_class, proc, keyword_args, regular_args = nil, operator = "", options = {} of Symbol => NoReturn)
      {% if regular_args.is_a?(ArrayLiteral) %}
        {% regular_arg_array = regular_args %}
      {% elsif regular_args == nil %}
        {% regular_arg_array = nil %}
      {% else %}
        {% regular_arg_array = [regular_args] %}
      {% end %}

      {% if !options[:block_arg_number] %}
        {% proc_arg_string = "" %}
      {% elsif options[:block_arg_number] == 0 %}
        {% proc_arg_string = "do" %}
      {% else %}
        {% proc_arg_string = "do |" + (0..options[:block_arg_number] - 1).map { |x| "block_arg_#{x}" }.join(", ") + "|" %}
      {% end %}

      {% options[:type_vars] = crystal_class.resolve.type_vars %}
      {% options[:type_var_names_annotation] = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}
      
      %wrapped_method = Anyolite::Macro.new_rb_func do
        %regular_arg_tuple = Anyolite::Macro.generate_arg_tuple(_rb, {{regular_arg_array}}, options: {{options}})

        {% if options[:block_arg_number] || options[:store_block_arg] %}
          %block_ptr = Pointer(Anyolite::RbCore::RbValue).malloc(size: 1)

          {% if options[:store_block_arg] %}
            Anyolite::RbArgCache.set_block_cache(%block_ptr)
          {% end %}

          %format_string = Anyolite::Macro.format_string({{regular_arg_array}}, options: {{options}}) + ":&"
          %kw_args = Anyolite::Macro.load_kw_args_into_vars({{regular_arg_array}}, {{keyword_args}}, %format_string, %regular_arg_tuple, %block_ptr)

          {% if options[:block_arg_number] %}
            if Anyolite::RbCast.check_for_nil(%block_ptr.value)
              Anyolite.raise_argument_error("No block given.")
              Anyolite::RbCast.return_nil
            end
          {% end %}
        {% else %}
          %block_ptr = nil
          %format_string = Anyolite::Macro.format_string({{regular_arg_array}}, options: {{options}}) + ":"
          %kw_args = Anyolite::Macro.load_kw_args_into_vars({{regular_arg_array}}, {{keyword_args}}, %format_string, %regular_arg_tuple)
        {% end %}

        %converted_regular_args = Anyolite::Macro.convert_regular_args(_rb, %regular_arg_tuple, {{regular_arg_array}}, context: {{options[:context]}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})

        {% if !regular_arg_array || regular_arg_array.size == 0 %}
          %new_obj = {{proc}}{{operator.id}}(
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal(_rb, %kw_args.values[{{c}}], {{keyword}}, context: {{options[:context]}}, 
                type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          ) {{proc_arg_string.id}}
        {% else %}
          %new_obj = {{proc}}{{operator.id}}(*%converted_regular_args,
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal(_rb, %kw_args.values[{{c}}], {{keyword}}, context: {{options[:context]}}, 
                type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          ) {{proc_arg_string.id}}
        {% end %}

        {% if options[:block_arg_number] == 0 %}
            %yield_value = Anyolite::RbCore.rb_yield(_rb, %block_ptr.value, Anyolite::RbCast.return_nil)
            Anyolite::Macro.convert_from_ruby_to_crystal(_rb, %yield_value, {{options[:block_return_type]}})
          end
        {% elsif options[:block_arg_number] %}
            %block_arg_array = [
              {% for i in 0..options[:block_arg_number] - 1 %}
                Anyolite::RbCast.return_value(_rb, {{"block_arg_#{i}".id}}),
              {% end %}
            ]
            %yield_value = Anyolite::RbCore.rb_yield_argv(_rb, %block_ptr.value, {{options[:block_arg_number]}}, %block_arg_array)
            Anyolite::Macro.convert_from_ruby_to_crystal(_rb, %yield_value, {{options[:block_return_type]}})
          end
        {% end %}

        Anyolite::Macro.allocate_constructed_object(_rb, {{crystal_class}}, _obj, %new_obj)

        {% if options[:store_block_arg] %}
          Anyolite::RbArgCache.reset_block_cache
        {% end %}
        
        _obj
      end

      {{rb_interpreter}}.define_method("initialize", Anyolite::RbClassCache.get({{crystal_class}}), %wrapped_method)
    end

    macro wrap_equality_function(rb_interpreter, crystal_class, name, proc, operator = "", context = nil)
      {% options = {:context => context} %}
      
      {% options[:type_vars] = crystal_class.resolve.type_vars %}
      {% options[:type_var_names_annotation] = crystal_class.resolve.annotation(Anyolite::SpecifyGenericTypes) %}
      {% options[:type_var_names] = options[:type_var_names_annotation] ? options[:type_var_names_annotation][0] : nil %}

      %wrapped_method = Anyolite::Macro.new_rb_func do
        %args = Anyolite::Macro.generate_arg_tuple(_rb, [other : {{crystal_class}}], options: {{options}})
        %format_string = Anyolite::Macro.format_string([other : {{crystal_class}}], options: {{options}})
      
        Anyolite::Macro.load_args_into_vars([other : {{crystal_class}}], %format_string, %args)

        if !Anyolite::RbCast.check_custom_type(_rb, %args[0].value, {{crystal_class}})
          Anyolite::RbCast.return_false
        else
          %converted_args = Anyolite::Macro.convert_regular_args(_rb, %args, [other : {{crystal_class}}], context: {{context}}, type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}})

          if {{crystal_class}} <= Struct || {{crystal_class}} <= Enum
            %converted_obj = Anyolite::Macro.convert_from_ruby_struct(_rb, _obj, {{crystal_class}}).value
          else
            %converted_obj = Anyolite::Macro.convert_from_ruby_object(_rb, _obj, {{crystal_class}}).value
          end

          %return_value = Anyolite::Macro.call_and_return_instance_method(_rb, {{proc}}, %converted_obj, %converted_args, operator: {{operator}}, options: {{options}})

          %return_value
        end
      end

      {{rb_interpreter}}.define_method({{name}}, Anyolite::RbClassCache.get({{crystal_class}}), %wrapped_method)
    end

    macro wrap_constant_or_class(rb_interpreter, under_class_or_module, ruby_name, value, overwrite = false, verbose = false)
      {% actual_constant = under_class_or_module.resolve.constant(value.id) %}
      {% if actual_constant.is_a?(TypeNode) %}
        {% if actual_constant.module? %}
          Anyolite.wrap_module_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, overwrite: {{overwrite}}, verbose: {{verbose}})
        {% elsif actual_constant.class? || actual_constant.struct? %}
          Anyolite.wrap_class_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, wrap_equality_method: {{actual_constant.struct?}}, overwrite: {{overwrite}}, verbose: {{verbose}})
        {% elsif actual_constant.union? %}
          {% puts "\e[31m> WARNING: Wrapping of unions not supported, thus skipping #{actual_constant}\e[0m" %}
        {% elsif actual_constant < Enum %}
          Anyolite.wrap_class_with_methods({{rb_interpreter}}, {{actual_constant}}, under: {{under_class_or_module}}, use_enum_methods: true, wrap_equality_method: true, overwrite: {{overwrite}}, verbose: {{verbose}})
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
