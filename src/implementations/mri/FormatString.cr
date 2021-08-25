module Anyolite
  module Macro
    macro format_string(args, context = nil)
      {% if args %}
        {% required_counter = 0 %}
        {% optional_counter = 0 %}
        {% optional_args = false %}

        {% for arg in args %}
          {% if arg.is_a?(TypeDeclaration) %}
            {% if arg.value || optional_args %}
              {% optional_counter += 1 %}
              {% optional_args = true %}
            {% else %}
              {% required_counter += 1 %}
            {% end %}
          {% else %}
            {% if optional_args %}
              {% optional_counter += 1 %}
            {% else %}
              {% required_counter += 1 %}
            {% end %}
          {% end %}
        {% end %}

        "{{required_counter}}{{optional_counter > 0 ? optional_counter : "".id}}"
      {% else %}
        ""
      {% end %}
    end
  end
end