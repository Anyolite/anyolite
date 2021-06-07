module Anyolite
  module Macro
    macro add_default_constructor(rb_interpreter, crystal_class, verbose)
      {% puts "> Adding constructor for #{crystal_class}\n\n" if verbose %}
      Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}})
    end

    macro add_enum_constructor(rb_interpreter, crystal_class, verbose)
      {% puts "> Adding enum constructor for #{crystal_class}\n\n" if verbose %}
      Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}}, [Int32])
    end

    macro add_equality_method(rb_interpreter, crystal_class, context, verbose)
      {% puts "> Adding equality method for #{crystal_class}\n\n" if verbose %}
      Anyolite.wrap_instance_method({{rb_interpreter}}, {{crystal_class}}, "==", Anyolite::Empty, [other : {{crystal_class}}], operator: "==", context: {{context}})
    end
  end
end