module Anyolite
  module Macro
    macro wrap_method_index(rb_interpreter, crystal_class, method_index, ruby_name,
                            is_constructor = false, is_class_method = false,
                            operator = "", cut_name = nil,
                            without_keywords = false, added_keyword_args = nil,
                            context = nil, return_nil = false,
                            block_arg_number = nil, block_return_type = nil,
                            store_block_arg = false)

      {% if is_class_method %}
        {% method = crystal_class.resolve.class.methods[method_index] %}
      {% else %}
        {% method = crystal_class.resolve.methods[method_index] %}
      {% end %}

      {% if !operator.empty? %}
        {% if cut_name %}
          {% if is_class_method %}
            {% final_method_name = "#{crystal_class}.#{cut_name}".id %}
            {% final_operator = "#{crystal_class}.#{operator.id}" %}
          {% else %}
            {% final_method_name = cut_name %}
            {% final_operator = operator %}
          {% end %}
        {% else %}
          {% final_method_name = Anyolite::Empty %}
          {% if is_class_method %}
            {% final_operator = "#{crystal_class}.#{operator.id}" %}
          {% else %}
            {% final_operator = operator %}
          {% end %}
        {% end %}
      {% else %}
        {% if is_class_method %}
          {% final_method_name = "#{crystal_class}.#{method.name}".id %}
        {% else %}
          {% final_method_name = method.name %}
        {% end %}
        {% final_operator = operator %}
      {% end %}

      {% final_arg_array = added_keyword_args ? added_keyword_args : method.args %}

      # TODO: Make something with block args

      {% if final_arg_array.empty? %}
        {% if is_class_method %}
          Anyolite.wrap_class_method({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, operator: {{final_operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
        {% elsif is_constructor %}
          # Do not ever let a constructor return nil (for now)
          Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}}, context: {{context}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
        {% else %}
          Anyolite.wrap_instance_method({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, operator: {{final_operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
        {% end %}

      # A complicated check, but it is more stable than simply checking for colons
      {% elsif final_arg_array.find { |m| (m.is_a?(TypeDeclaration) && m.type) || (m.is_a?(Arg) && m.restriction) } %}
        {% if without_keywords %}
          {% if without_keywords >= final_arg_array.size %}
            {% regular_arg_partition = nil %}
            {% keyword_arg_partition = final_arg_array %}
          {% elsif without_keywords < 0 %}
            {% regular_arg_partition = final_arg_array %}
            {% keyword_arg_partition = nil %}
          {% else %}
            {% regular_arg_partition = final_arg_array[0 .. without_keywords - 1] %}
            {% keyword_arg_partition = final_arg_array[without_keywords .. -1] %}
          {% end %}

          {% if keyword_arg_partition %}
            {% if is_class_method %}
              Anyolite.wrap_class_method_with_keywords({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
                {{keyword_arg_partition}}, regular_args: {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
            {% elsif is_constructor %}
              Anyolite.wrap_constructor_with_keywords({{rb_interpreter}}, {{crystal_class}}, 
                {{keyword_arg_partition}}, regular_args: {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
            {% else %}
              Anyolite.wrap_instance_method_with_keywords({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
                {{keyword_arg_partition}}, regular_args: {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
            {% end %}
          {% else %}
            {% if is_class_method %}
              Anyolite.wrap_class_method({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
                {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
            {% elsif is_constructor %}
              Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}}, 
                {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
            {% else %}
              Anyolite.wrap_instance_method({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
                {{regular_arg_partition}}, operator: {{final_operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
            {% end %}
          {% end %}
        {% else %}
          {% if is_class_method %}
            Anyolite.wrap_class_method_with_keywords({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
              {{final_arg_array}}, operator: {{final_operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
          {% elsif is_constructor %}
            Anyolite.wrap_constructor_with_keywords({{rb_interpreter}}, {{crystal_class}}, 
              {{final_arg_array}}, operator: {{final_operator}}, context: {{context}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
          {% else %}
            Anyolite.wrap_instance_method_with_keywords({{rb_interpreter}}, {{crystal_class}}, {{ruby_name}}, {{final_method_name}}, 
              {{final_arg_array}}, operator: {{final_operator}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
          {% end %}
        {% end %}

      {% else %}
        {% if is_class_method %}
          {% puts "\e[33m> INFO: Could not wrap function '#{crystal_class}.#{method.name}' with args #{method.args}.\e[0m" %}
        {% else %}
          {% puts "\e[33m> INFO: Could not wrap function '#{method.name}' with args #{method.args}.\e[0m" %}
        {% end %}
      {% end %}
    end
  end
end