require "./MrbInternal.cr"

require "./MrbState.cr"
require "./MrbClass.cr"
require "./MrbCast.cr"
require "./MrbMacro.cr"
require "./MrbClassCache.cr"
require "./MrbModuleCache.cr"
require "./MrbTypeCache.cr"
require "./MrbModule.cr"
require "./MrbRefTable.cr"

# Alias for the mruby function pointers
alias MrbFunc = Proc(MrbInternal::MrbState*, MrbInternal::MrbValue, MrbInternal::MrbValue)

# Main wrapper module, which should be covering most of the use cases
module MrbWrap

  # Alias for all possible mruby return types
  alias Interpreted = Nil | Bool | MrbInternal::MrbFloat | MrbInternal::MrbInt | String | Undefined

  # Special struct representing undefined values in mruby
  struct Undefined
    # :nodoc:
    def initialize
    end
  end

  class StructWrapper(T)
    @content : T | Nil = nil

    def initialize(value)
      @content = value
    end

    def content : T
      if c = @content 
        c
      else
        raise("Content undefined!")
      end
    end

    def content=(value)
      @content = value
    end
  end

  # Undefined mruby value
  Undef = Undefined.new

  # Wraps a Crystal class directly into an mruby class.
  # 
  # The Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with *name* as its new designation, returning an `MrbClass`.
  # 
  # To inherit from another mruby class, specify an `MrbClass` as a *superclass*.
  #
  # Each class can be defined in a specifiy module by setting *under* to a `MrbModule`.
  macro wrap_class(mrb_state, crystal_class, name, under = nil, superclass = nil)
    new_class = MrbClass.new({{mrb_state}}, {{name}}, under: MrbModuleCache.get({{under}}), superclass: MrbClassCache.get({{superclass}}))
    MrbInternal.set_instance_tt_as_data(new_class)
    MrbClassCache.register({{crystal_class}}, new_class)
    MrbClassCache.get({{crystal_class}})
  end

  # Wraps a Crystal module into an mruby module.
  # 
  # The module *crystal_module* will be integrated into the `MrbState` *mrb_state*,
  # with *name* as its new designation, returning an `MrbModule`.
  # 
  # The parent module can be specified with the module argument *under*.
  macro wrap_module(mrb_state, crystal_module, name, under = nil)
    new_module = MrbModule.new({{mrb_state}}, {{name}}, under: MrbModuleCache.get({{under}}))
    MrbModuleCache.register({{crystal_module}}, new_module)
    MrbModuleCache.get({{crystal_module}})
  end

  # Wraps the constructor of a Crystal class into mruby.
  # 
  # The constructor for the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  macro wrap_constructor(mrb_state, crystal_class, proc_args = [] of Class, operator = "")
    MrbMacro.wrap_constructor_function_with_args({{mrb_state}}, {{crystal_class}}, {{crystal_class}}.new, {{proc_args}}, operator: {{operator}})
  end

  # Wraps the constructor of a Crystal class into mruby, using keyword arguments.
  # 
  # The constructor for the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as a `Hash of Symbol => Class`.
  # Alternatively, a `Tuple` with the `Class` and a default value for the `Class` can be used instead of the `Class`.
  macro wrap_constructor_with_keywords(mrb_state, crystal_class, keyword_args, regular_args = [] of Class, operator = "")
    MrbMacro.wrap_constructor_function_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{crystal_class}}.new, {{keyword_args}}, {{regular_args}}, operator: {{operator}})
  end

  # Wraps a module function into mruby.
  # 
  # The function *proc* under the module *under_module* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_module_function(mrb_state, under_module, name, proc, proc_args = [] of Class, operator = "")
    MrbMacro.wrap_module_function_with_args({{mrb_state}}, {{under_module}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}})
  end

  # Wraps a module function into mruby, using keyword arguments.
  # 
  # The function *proc* under the module *under_module* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as a `Hash of Symbol => Class`.
  # Alternatively, a `Tuple` with the `Class` and a default value for the `Class` can be used instead of the `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_module_function_with_keywords(mrb_state, under_module, name, proc, keyword_args, regular_args = [] of Class, operator = "")
    MrbMacro.wrap_module_function_with_keyword_args({{mrb_state}}, {{under_module}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}})
  end

  # Wraps a class method into mruby.
  # 
  # The class method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_class_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class, operator = "")
    MrbMacro.wrap_class_method_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}})
  end

  # Wraps a class method into mruby, using keyword arguments.
  # 
  # The class method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as a `Hash of Symbol => Class`.
  # Alternatively, a `Tuple` with the `Class` and a default value for the `Class` can be used instead of the `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_class_method_with_keywords(mrb_state, crystal_class, name, proc, keyword_args, regular_args = [] of Class, operator = "")
    MrbMacro.wrap_class_method_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}})
  end

  # Wraps an instance method into mruby.
  # 
  # The instance method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *proc_args* as an `Array of Class`.
  # 
  # Its new name will be *name*.
  macro wrap_instance_method(mrb_state, crystal_class, name, proc, proc_args = [] of Class, operator = "")
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_args}}, operator: {{operator}})
  end
  
  # Wraps an instance method into mruby, using keyword arguments.
  # 
  # The instance method *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the arguments *regular_args* as an `Array of Class` and *keyword_args* as a `Hash of Symbol => Class`.
  # Alternatively, a `Tuple` with the `Class` and a default value for the `Class` can be used instead of the `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_instance_method_with_keywords(mrb_state, crystal_class, name, proc, keyword_args, regular_args = [] of Class, operator = "")
    MrbMacro.wrap_instance_function_with_keyword_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{keyword_args}}, {{regular_args}}, operator: {{operator}})
  end

  # Wraps a setter into mruby.  
  # 
  # The setter *proc* (without the `=`) of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the argument *proc_arg* as its respective `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_setter(mrb_state, crystal_class, name, proc, proc_arg, operator = "=")
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_arg}}, operator: {{operator}})
  end

  # Wraps a getter into mruby.  
  # 
  # The getter *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*.
  # 
  # Its new name will be *name*.
  macro wrap_getter(mrb_state, crystal_class, name, proc, operator = "")
    MrbMacro.wrap_instance_function_with_args({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, operator: {{operator}})
  end

  # Wraps a property into mruby.  
  # 
  # The property *proc* of the Crystal `Class` *crystal_class* will be integrated into the `MrbState` *mrb_state*,
  # with the argument *proc_arg* as its respective `Class`.
  # 
  # Its new name will be *name*.
  macro wrap_property(mrb_state, crystal_class, name, proc, proc_arg, operator_getter = "", operator_setter = "=")
    MrbWrap.wrap_getter({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, operator: {{operator_getter}})
    MrbWrap.wrap_setter({{mrb_state}}, {{crystal_class}}, {{name}}, {{proc}}, {{proc_arg}}, operator: {{operator_setter}})
  end

  # Wraps a constant value under a module into mruby.
  # 
  # The value *crystal_value* will be integrated into the `MrbState` *mrb_state*,
  # with the name *name* and the parent module *under_module*.
  macro wrap_constant(mrb_state, under_module, name, crystal_value)
    MrbInternal.mrb_define_const({{mrb_state}}, MrbModuleCache.get({{under_module}}), {{name}}, MrbCast.return_value({{mrb_state}}.to_unsafe, {{crystal_value}}))
  end

  # Wraps a constant value under a class into mruby.
  # 
  # The value *crystal_value* will be integrated into the `MrbState` *mrb_state*,
  # with the name *name* and the parent `Class` *under_class*.
  macro wrap_constant_under_class(mrb_state, under_class, name, crystal_value)
    MrbInternal.mrb_define_const({{mrb_state}}, MrbClassCache.get({{under_class}}), {{name}}, MrbCast.return_value({{mrb_state}}.to_unsafe, {{crystal_value}}))
  end

  annotation Exclude
  end

  annotation Specialize
  end

  annotation Rename
  end

  annotation ExcludeInstanceMethod
  end

  annotation SpecializeInstanceMethod
  end

  annotation RenameInstanceMethod
  end

  macro wrap_class_with_methods(mrb_state, crystal_class, under = nil, exclusions = [] of String | Symbol, verbose = false)
    MrbWrap.wrap_class({{mrb_state}}, {{crystal_class.resolve}}, "{{crystal_class}}", under: {{under}})

    # Things left to do:
    # - Simplify the whole function with more macros
    # - Allow passing normal and keyword argument arrays to specialization annotations as optional arguments
    # - Introduce macro for how_many_times_wrapped checks
    # - Handle operators correctly
    # - Allow for passing of information (via annotations?) to specify or exclude functions
    # - Update class method and constant wrapping to behave like the instance method wrappers
    # - Wrap modules similarly to classes
    # - Wrap stuff from inherited classes if wanted
    # - Display warning if a function gets wrapped more than once
    # - Display function args for repeated wrapping (replaced ones and new ones?)
    # - Allow flag for setting all required function arguments as non-keyword-based
    # - Maybe pass functions as symbols to fix operators?
    # - Fix transformations of methods to ruby setters (and vice versa), which will currently not work
    # - Flag to include finalize

    {% has_specialized_method = {} of String => Bool %}

    {% for method in crystal_class.resolve.methods %}
      {% all_annotations_exclude_im = crystal_class.resolve.annotations(MrbWrap::ExcludeInstanceMethod) %}
      {% annotation_exclude_im = all_annotations_exclude_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_specialize_im = crystal_class.resolve.annotations(MrbWrap::SpecializeInstanceMethod) %}
      {% annotation_specialize_im = all_annotations_specialize_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_rename_im = crystal_class.resolve.annotations(MrbWrap::RenameInstanceMethod) %}
      {% annotation_rename_im = all_annotations_rename_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% if method.annotation(MrbWrap::Specialize) %}
        {% has_specialized_method[method.name.stringify] = true %}
      {% end %}

      {% if annotation_specialize_im %}
        {% has_specialized_method[annotation_specialize_im[0].stringify] = true %}
      {% end %}
    {% end %}

    # TODO: Replace the above when ready
    specialized_methods = MrbMacro.get_specialized_methods({{crystal_class}})

    {% how_many_times_wrapped = {} of String => UInt32 %}

    {% for method in crystal_class.resolve.methods %}
      {% all_annotations_exclude_im = crystal_class.resolve.annotations(MrbWrap::ExcludeInstanceMethod) %}
      {% annotation_exclude_im = all_annotations_exclude_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_specialize_im = crystal_class.resolve.annotations(MrbWrap::SpecializeInstanceMethod) %}
      {% annotation_specialize_im = all_annotations_specialize_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% all_annotations_rename_im = crystal_class.resolve.annotations(MrbWrap::RenameInstanceMethod) %}
      {% annotation_rename_im = all_annotations_rename_im.find {|element| element[0].stringify == method.name.stringify} %}

      {% if method.annotation(MrbWrap::Rename) %}
        {% ruby_name = method.annotation(MrbWrap::Rename)[0].id %}
      {% elsif annotation_rename_im && method.name.stringify == annotation_rename_im[0].stringify %}
        {% ruby_name = annotation_rename_im[1].id %}
      {% else %}
        {% ruby_name = method.name %}
      {% end %}

      # TODO: Why is the annotation for the function def not included in the passed method parameter?!?
      # TODO: Might be worth an issue
      puts "Ruby name of {{method.name}} is: #{MrbMacro.get_ruby_name({{crystal_class}}, {{method}})}"

      {% puts "> Processing #{crystal_class}::#{method.name} to #{ruby_name}" if verbose %}
      # Ignore mrb hooks
      {% if method.name.starts_with?("mrb_") || method.name == "finalize" %}
      # Exclude methods if given as arguments
      {% elsif exclusions.includes?(method.name.symbolize) || exclusions.includes?(method.name) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion argument)" if verbose %}
      # Exclude methods which were annotated to be excluded
      {% elsif method.annotation(MrbWrap::Exclude) || (annotation_exclude_im) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion annotation)" if verbose %}
      # Exclude methods which are not the specialized methods
      {% elsif has_specialized_method[method.name.stringify] && !(method.annotation(MrbWrap::Specialize) || (annotation_specialize_im && method.args.stringify == annotation_specialize_im[1].stringify)) %}
        {% puts "--> Excluding #{crystal_class}::#{method.name} (Specialization 1)" if verbose %}
      # Handle setters
      {% elsif method.name[-1..-1] == "=" %}
        # The '=' will be added later on (to the name and the method), so we can cut it here
        MrbWrap.wrap_setter({{mrb_state}}, {{crystal_class}}, "{{ruby_name[0..-2]}}", {{method.name[0..-2]}}, {{method.args[0].restriction}})
        {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
      # Handle constructors
      {% elsif method.name == "initialize" %}
        {% if method.args.empty? %}
          MrbWrap.wrap_constructor({{mrb_state}}, {{crystal_class}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        {% elsif method.args.stringify.includes?(":") %}
          # TODO: Put this in MrbMacro or some other module
          {% keyword_hash = {} of Symbol => Crystal::Macros::ASTNode %}
          {% for arg in method.args %}
            {% if arg.default_value.stringify != "" %}
              {% keyword_hash[arg.name.symbolize] = {arg.restriction, arg.default_value} %}
            {% else %}
              {% keyword_hash[arg.name.symbolize] = arg.restriction %}
            {% end %}
          {% end %}
          MrbWrap.wrap_constructor_with_keywords({{mrb_state}}, {{crystal_class}}, {{keyword_hash}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        {% else %}
          {% puts "INFO: Could not wrap function '#{method.name}' with args #{method.args}." %}
        {% end %}
      # Handle other instance methods
      {% else %}
        {% if method.args.empty? %}
          MrbWrap.wrap_instance_method({{mrb_state}}, {{crystal_class}}, "{{ruby_name}}", {{method.name}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        {% elsif method.args.stringify.includes?(":") %}
          {% keyword_hash = {} of Symbol => Crystal::Macros::ASTNode %}
          {% for arg in method.args %}
            {% if arg.default_value.stringify != "" %}
              {% if !arg.restriction %}
                {% puts "INFO: Could not wrap function '#{method.name}' with args #{method.args}." %}
                {% next %}
              {% else %}
                {% keyword_hash[arg.name.symbolize] = {arg.restriction, arg.default_value} %}
              {% end %}
            {% else %}
              {% keyword_hash[arg.name.symbolize] = arg.restriction %}
            {% end %}
          {% end %}
          MrbWrap.wrap_instance_method_with_keywords({{mrb_state}}, {{crystal_class}}, "{{ruby_name}}", {{method.name}}, {{keyword_hash}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        {% else %}
          {% puts "INFO: Could not wrap function '#{method.name}' with args #{method.args}." %}
        {% end %}
      {% end %}
    {% end %}

    {% if !how_many_times_wrapped["initialize"] %}
      {% puts "> Adding constructor for #{crystal_class}" if verbose %}
      MrbWrap.wrap_constructor({{mrb_state}}, {{crystal_class}})
    {% end %}

    {% for method in crystal_class.resolve.class.methods %}
      # We already wrapped 'initialize', so we don't need to wrap these
      {% if method.name == "allocate" || method.name == "new" %}
      # Handle other class methods
      {% else %}
        {% if method.args.empty? %}
          MrbWrap.wrap_class_method({{mrb_state}}, {{crystal_class}}, "{{method.name}}", {{crystal_class}}.{{method.name}})
        {% elsif method.args.stringify.includes?(":") %}
          {% keyword_hash = {} of Symbol => Crystal::Macros::ASTNode %}
          {% for arg in method.args %}
            {% if arg.default_value.stringify != "" %}
              {% keyword_hash[arg.name.symbolize] = {arg.restriction, arg.default_value} %}
            {% else %}
              {% keyword_hash[arg.name.symbolize] = arg.restriction %}
            {% end %}
          {% end %}
          MrbWrap.wrap_class_method_with_args({{mrb_state}}, {{crystal_class}}, "{{method.name}}", {{crystal_class}}.{{method.name}}, {{keyword_hash}})
        {% else %}
          {% puts "INFO: Could not wrap function '#{crystal_class}.#{method.name}' with args #{method.args}." %}
        {% end %}
      {% end %}
    {% end %}

    {% for constant in crystal_class.resolve.constants %}
      MrbWrap.wrap_constant_under_class({{mrb_state}}, {{crystal_class}}, "{{constant}}", {{crystal_class}}::{{constant}})
    {% end %}

  end
end
