module Anyolite
  module Macro
    macro call_and_return(rb, proc, regular_args, converted_args, operator = "", options = {} of Symbol => NoReturn, block_ptr = nil)
      {% if !options[:block_arg_number] %}
        {% proc_arg_string = "" %}
      {% elsif options[:block_arg_number] == 0 %}
        {% proc_arg_string = "do" %}
      {% else %}
        {% proc_arg_string = "do |" + (0..options[:block_arg_number] - 1).map { |x| "block_arg_#{x}" }.join(", ") + "|" %}
      {% end %}

      {% if proc.stringify == "Anyolite::Empty" %}
        %return_value = {{operator.id}}(*{{converted_args}}) {{proc_arg_string.id}}
      {% else %}
        %return_value = {{proc}}{{operator.id}}(*{{converted_args}}) {{proc_arg_string.id}}
      {% end %}

      {% if options[:block_arg_number] == 0 %}
          %yield_value = Anyolite::RbCore.rb_yield({{rb}}, {{block_ptr}}.value, Anyolite::RbCast.return_nil)
          Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
        end
      {% elsif options[:block_arg_number] %}
          %block_arg_array = [
            {% for i in 0..options[:block_arg_number] - 1 %}
              Anyolite::RbCast.return_value({{rb}}, {{"block_arg_#{i}".id}}),
            {% end %}
          ]
          %yield_value = Anyolite::RbCore.rb_yield_argv({{rb}}, {{block_ptr}}.value, {{options[:block_arg_number]}}, %block_arg_array)
          Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
        end
      {% end %}

      {% if options[:return_nil] %}
        Anyolite::RbCast.return_nil
      {% else %}
        Anyolite::RbCast.return_value({{rb}}, %return_value)
      {% end %}
    end

    macro call_and_return_keyword_method(rb, proc, converted_regular_args, keyword_args, kw_args, operator = "", options = {} of Symbol => NoReturn, block_ptr = nil)
      {% if !options[:block_arg_number] %}
        {% proc_arg_string = "" %}
      {% elsif options[:block_arg_number] == 0 %}
        {% proc_arg_string = "do" %}
      {% else %}
        {% proc_arg_string = "do |" + (0..options[:block_arg_number] - 1).map { |x| "block_arg_#{x}" }.join(", ") + "|" %}
      {% end %}

      {% if proc.stringify == "Anyolite::Empty" %}
        %return_value = {{operator.id}}(
      {% else %}
        %return_value = {{proc}}{{operator.id}}(
      {% end %}
        {% if options[:empty_regular] %}
          {% c = 0 %}
          {% for keyword in keyword_args %}
            {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{options[:context]}}, 
              type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
            {% c += 1 %}
          {% end %}
        {% else %}
          *{{converted_regular_args}},
          {% c = 0 %}
          {% for keyword in keyword_args %}
            {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{options[:context]}}, 
              type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
            {% c += 1 %}
          {% end %}
        {% end %}
      ) {{proc_arg_string.id}}

      {% if options[:block_arg_number] == 0 %}
          %yield_value = Anyolite::RbCore.rb_yield({{rb}}, {{block_ptr}}.value, Anyolite::RbCast.return_nil)
          Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{block_return_type}})
        end
      {% elsif options[:block_arg_number] %}
          %block_arg_array = [
            {% for i in 0..options[:block_arg_number] - 1 %}
              Anyolite::RbCast.return_value({{rb}}, {{"block_arg_#{i}".id}}),
            {% end %}
          ]
          %yield_value = Anyolite::RbCore.rb_yield_argv({{rb}}, {{block_ptr}}.value, {{options[:block_arg_number]}}, %block_arg_array)
          Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
        end
      {% end %}

      {% if options[:return_nil] %}
        Anyolite::RbCast.return_nil
      {% else %}
        Anyolite::RbCast.return_value({{rb}}, %return_value)
      {% end %}
    end

    macro call_and_return_instance_method(rb, proc, converted_obj, converted_args, operator = "", options = {} of Symbol => NoReturn, block_ptr = nil)
      {% if !options[:block_arg_number] %}
        {% proc_arg_string = "" %}
      {% elsif options[:block_arg_number] == 0 %}
        {% proc_arg_string = "do" %}
      {% else %}
        {% proc_arg_string = "do |" + (0..options[:block_arg_number] - 1).map { |x| "block_arg_#{x}" }.join(", ") + "|" %}
      {% end %}
      
      if {{converted_obj}}.is_a?(Anyolite::StructWrapper)
        %working_content = {{converted_obj}}.content

        {% if proc.stringify == "Anyolite::Empty" %}
          %return_value = %working_content.{{operator.id}}(*{{converted_args}}) {{proc_arg_string.id}}
        {% else %}
          %return_value = %working_content.{{proc}}{{operator.id}}(*{{converted_args}}) {{proc_arg_string.id}}
        {% end %}

        {% if options[:block_arg_number] == 0 %}
            %yield_value = Anyolite::RbCore.rb_yield({{rb}}, {{block_ptr}}.value, Anyolite::RbCast.return_nil)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
          end
        {% elsif options[:block_arg_number] %}
            %block_arg_array = [
              {% for i in 0..options[:block_arg_number] - 1 %}
                Anyolite::RbCast.return_value({{rb}}, {{"block_arg_#{i}".id}}),
              {% end %}
            ]
            %yield_value = Anyolite::RbCore.rb_yield_argv({{rb}}, {{block_ptr}}.value, {{options[:block_arg_number]}}, %block_arg_array)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
          end
        {% end %}

        {{converted_obj}}.content = %working_content
      else
        {% if proc.stringify == "Anyolite::Empty" %}
          %return_value = {{converted_obj}}.{{operator.id}}(*{{converted_args}}) {{proc_arg_string.id}}
        {% else %}
          %return_value = {{converted_obj}}.{{proc}}{{operator.id}}(*{{converted_args}}) {{proc_arg_string.id}}
        {% end %}

        {% if options[:block_arg_number] == 0 %}
            %yield_value = Anyolite::RbCore.rb_yield({{rb}}, {{block_ptr}}.value, Anyolite::RbCast.return_nil)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
          end
        {% elsif options[:block_arg_number] %}
            %block_arg_array = [
              {% for i in 0..options[:block_arg_number] - 1 %}
                Anyolite::RbCast.return_value({{rb}}, {{"block_arg_#{i}".id}}),
              {% end %}
            ]
            %yield_value = Anyolite::RbCore.rb_yield_argv({{rb}}, {{block_ptr}}.value, {{options[:block_arg_number]}}, %block_arg_array)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
          end
        {% end %}
      end

      {% if options[:return_nil] %}
        Anyolite::RbCast.return_nil
      {% else %}
        Anyolite::RbCast.return_value({{rb}}, %return_value)
      {% end %}
    end

    macro call_and_return_keyword_instance_method(rb, proc, converted_obj, converted_regular_args, keyword_args, kw_args, operator = "", options = {} of Symbol => NoReturn, block_ptr = nil)
      {% if !options[:block_arg_number] %}
        {% proc_arg_string = "" %}
      {% elsif options[:block_arg_number] == 0 %}
        {% proc_arg_string = "do" %}
      {% else %}
        {% proc_arg_string = "do |" + (0..options[:block_arg_number] - 1).map { |x| "block_arg_#{x}" }.join(", ") + "|" %}
      {% end %}

      if {{converted_obj}}.is_a?(Anyolite::StructWrapper)
        %working_content = {{converted_obj}}.content

        {% if proc.stringify == "Anyolite::Empty" %}
          %return_value = %working_content.{{operator.id}}(
        {% else %}
          %return_value = %working_content.{{proc}}{{operator.id}}(
        {% end %}
          {% if options[:empty_regular] %}
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{options[:context]}}, 
                type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          {% else %}
            *{{converted_regular_args}},
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{options[:context]}},
                type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          {% end %}
        ) {{proc_arg_string.id}}

        {% if options[:block_arg_number] == 0 %}
            %yield_value = Anyolite::RbCore.rb_yield({{rb}}, {{block_ptr}}.value, Anyolite::RbCast.return_nil)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
          end
        {% elsif options[:block_arg_number] %}
            %block_arg_array = [
              {% for i in 0..options[:block_arg_number] - 1 %}
                Anyolite::RbCast.return_value({{rb}}, {{"block_arg_#{i}".id}}),
              {% end %}
            ]
            %yield_value = Anyolite::RbCore.rb_yield_argv({{rb}}, {{block_ptr}}.value, {{options[:block_arg_number]}}, %block_arg_array)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
          end
        {% end %}

        {{converted_obj}}.content = %working_content
      else

        {% if proc.stringify == "Anyolite::Empty" %}
          %return_value = {{converted_obj}}.{{operator.id}}(
        {% else %}
          %return_value = {{converted_obj}}.{{proc}}{{operator.id}}(
        {% end %}
          {% if options[:empty_regular] %}
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{options[:context]}},
                type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          {% else %}
            *{{converted_regular_args}},
            {% c = 0 %}
            {% for keyword in keyword_args %}
              {{keyword.var.id}}: Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, {{kw_args}}.values[{{c}}], {{keyword}}, context: {{options[:context]}},
                type_vars: {{options[:type_vars]}}, type_var_names: {{options[:type_var_names]}}, debug_information: {{proc.stringify + " - " + keyword_args.stringify}}),
              {% c += 1 %}
            {% end %}
          {% end %}
        ) {{proc_arg_string.id}}

        {% if options[:block_arg_number] == 0 %}
            %yield_value = Anyolite::RbCore.rb_yield({{rb}}, {{block_ptr}}.value, Anyolite::RbCast.return_nil)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
          end
        {% elsif options[:block_arg_number] %}
            %block_arg_array = [
              {% for i in 0..options[:block_arg_number] - 1 %}
                Anyolite::RbCast.return_value({{rb}}, {{"block_arg_#{i}".id}}),
              {% end %}
            ]
            %yield_value = Anyolite::RbCore.rb_yield_argv({{rb}}, {{block_ptr}}.value, {{options[:block_arg_number]}}, %block_arg_array)
            Anyolite::Macro.convert_from_ruby_to_crystal({{rb}}, %yield_value, {{options[:block_return_type]}})
          end
        {% end %}
      end

      {% if options[:return_nil] %}
        Anyolite::RbCast.return_nil
      {% else %}
        Anyolite::RbCast.return_value({{rb}}, %return_value)
      {% end %}
    end
  end
end
