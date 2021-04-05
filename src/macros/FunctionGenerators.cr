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
  end
end