module Anyolite
  module Macro
    macro add_default_constructor(rb_interpreter, crystal_class, verbose)
      {% puts "> Adding constructor for #{crystal_class}\n\n" if verbose %}
      Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}})
    end

    macro add_enum_constructor(rb_interpreter, crystal_class, verbose)
      {% puts "> Adding enum constructor for #{crystal_class}\n\n" if verbose %}
      {% type_hash = {:u8 => UInt8, :u16 => UInt16, :u32 => UInt32, :u64 => UInt64, :i8 => Int8, :i16 => Int16, :i32 => Int32, :i64 => Int64} %}
      {% enum_type = type_hash[parse_type("#{crystal_class}::#{crystal_class.resolve.constants.first.id}").resolve.kind] %}
      Anyolite.wrap_constructor({{rb_interpreter}}, {{crystal_class}}, [{{enum_type}}])
    end

    macro add_enum_inspect(rb_interpreter, crystal_class, verbose)
      {% puts "> Adding enum inspect method for #{crystal_class}\n\n" if verbose %}
      Anyolite.wrap_instance_method({{rb_interpreter}}, {{crystal_class}}, "inspect", inspect)
    end

    macro add_enum_to_s(rb_interpreter, crystal_class, verbose)
      {% puts "> Adding enum to_s method for #{crystal_class}\n\n" if verbose %}
      Anyolite.wrap_instance_method({{rb_interpreter}}, {{crystal_class}}, "to_s", to_s)
    end

    macro add_equality_method(rb_interpreter, crystal_class, context, verbose)
      {% puts "> Adding equality method for #{crystal_class}\n\n" if verbose %}
      {% options = {:context => context} %}
      Anyolite::Macro.wrap_equality_function({{rb_interpreter}}, {{crystal_class}}, "==", Anyolite::Empty, operator: "==", options: {{options}})
    end

    macro add_copy_constructor(rb_interpreter, crystal_class, context, verbose)
      {% puts "> Adding copy constructor for #{crystal_class}\n\n" if verbose %}
      {% options = {:context => context} %}

      %copy_proc = Anyolite::Macro.new_rb_func do
        %converted_args = Anyolite::Macro.get_converted_args(_rb, [other : {{crystal_class}}], options: {{options}})
        %new_obj = %converted_args[0].dup
        Anyolite::Macro.allocate_constructed_object(_rb, {{crystal_class}}, _obj, %new_obj)
        _obj
      end

      {{rb_interpreter}}.define_method("initialize_copy", Anyolite::RbClassCache.get({{crystal_class}}), %copy_proc)
    end
  end
end
