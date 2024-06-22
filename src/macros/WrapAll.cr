module Anyolite
  module Macro
    macro wrap_all_instance_methods(rb_interpreter, crystal_class, exclusions, verbose, context = nil,
                                    use_enum_methods = false, wrap_equality_method = false, other_source = nil, later_ancestors = nil)
      {% has_specialized_method = {} of String => Bool %}

      {% method_source = other_source ? other_source : crystal_class %}

      {% default_optional_args_to_keyword_args = parse_type("ANYOLITE_DEFAULT_OPTIONAL_ARGS_TO_KEYWORD_ARGS").resolve? %}

      {% if !crystal_class.resolve.annotations(Anyolite::DefaultOptionalArgsToKeywordArgs).empty? %}
        {% default_optional_args_to_keyword_args = true %}
      {% else %}
        {% for class_ancestor in crystal_class.resolve.ancestors %}
          {% if !class_ancestor.resolve.annotations(Anyolite::DefaultOptionalArgsToKeywordArgs).empty? %}
            {% default_optional_args_to_keyword_args = true %}
          {% end %}
        {% end %}
      {% end %}

      {% if !method_source.resolve? %}
        {% puts "> Skipping #{method_source} due to private visibility." if verbose %}
      {% else %}
        {% for method in method_source.resolve.methods %}
          {% all_annotations_specialize_im = crystal_class.resolve.annotations(Anyolite::SpecializeInstanceMethod) + method_source.resolve.annotations(Anyolite::SpecializeInstanceMethod) %}
          {% annotation_specialize_im = all_annotations_specialize_im.find { |element| element[0].stringify == method.name.stringify || element[0] == method.name.stringify } %}

          {% if method.annotation(Anyolite::Specialize) %}
            {% has_specialized_method[method.name.stringify] = true %}
          {% end %}

          {% if annotation_specialize_im %}
            {% has_specialized_method[annotation_specialize_im[0].id.stringify] = true %}
          {% end %}
        {% end %}

        {% how_many_times_wrapped = {} of String => UInt32 %}

        {% for method, index in method_source.resolve.methods %}
          {% all_annotations_exclude_im = crystal_class.resolve.annotations(Anyolite::ExcludeInstanceMethod) + method_source.resolve.annotations(Anyolite::ExcludeInstanceMethod) + crystal_class.resolve.ancestors.map { |ancestor| ancestor.resolve.annotations(Anyolite::ExcludeInstanceMethod) } %}
          {% annotation_exclude_im = all_annotations_exclude_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% all_annotations_include_im = crystal_class.resolve.annotations(Anyolite::IncludeInstanceMethod) + method_source.resolve.annotations(Anyolite::IncludeInstanceMethod) %}
          {% annotation_include_im = all_annotations_include_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% all_annotations_specialize_im = crystal_class.resolve.annotations(Anyolite::SpecializeInstanceMethod) + method_source.resolve.annotations(Anyolite::SpecializeInstanceMethod) %}
          {% annotation_specialize_im = all_annotations_specialize_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% all_annotations_rename_im = crystal_class.resolve.annotations(Anyolite::RenameInstanceMethod) + method_source.resolve.annotations(Anyolite::RenameInstanceMethod) %}
          {% annotation_rename_im = all_annotations_rename_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% all_annotations_without_keywords_im = crystal_class.resolve.annotations(Anyolite::WrapWithoutKeywordsInstanceMethod) + method_source.resolve.annotations(Anyolite::WrapWithoutKeywordsInstanceMethod) %}
          {% annotation_without_keyword_im = all_annotations_without_keywords_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% all_annotations_return_nil_im = crystal_class.resolve.annotations(Anyolite::ReturnNilInstanceMethod) + method_source.resolve.annotations(Anyolite::ReturnNilInstanceMethod) %}
          {% annotation_return_nil_im = all_annotations_return_nil_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% all_annotations_add_block_arg_im = crystal_class.resolve.annotations(Anyolite::AddBlockArgInstanceMethod) + method_source.resolve.annotations(Anyolite::AddBlockArgInstanceMethod) %}
          {% annotation_add_block_arg_im = all_annotations_add_block_arg_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% all_annotations_store_block_arg_im = crystal_class.resolve.annotations(Anyolite::StoreBlockArgInstanceMethod) + method_source.resolve.annotations(Anyolite::StoreBlockArgInstanceMethod) %}
          {% annotation_store_block_arg_im = all_annotations_store_block_arg_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% all_annotations_force_keyword_arg_im = crystal_class.resolve.annotations(Anyolite::ForceKeywordArgInstanceMethod) + method_source.resolve.annotations(Anyolite::ForceKeywordArgInstanceMethod) %}
          {% annotation_force_keyword_arg_im = all_annotations_force_keyword_arg_im.find { |element| element[0].id.stringify == method.name.stringify } %}

          {% if crystal_class.resolve.annotation(Anyolite::NoKeywordArgs) || method_source.resolve.annotation(Anyolite::NoKeywordArgs) %}
            {% no_keyword_args = true %}
          {% else %}
            {% no_keyword_args = false %}
          {% end %}

          {% if method.annotation(Anyolite::Rename) %}
            {% ruby_name = method.annotation(Anyolite::Rename)[0].id %}
          {% elsif annotation_rename_im && method.name.stringify == annotation_rename_im[0].id.stringify %}
            {% ruby_name = annotation_rename_im[1].id %}
          {% else %}
            {% ruby_name = method.name %}
          {% end %}

          {% if method.annotation(Anyolite::AddBlockArg) %}
            {% block_arg_number = method.annotation(Anyolite::AddBlockArg)[0] %}
            {% block_return_type = method.annotation(Anyolite::AddBlockArg)[1] %}
          {% elsif annotation_add_block_arg_im && method.name.stringify == annotation_add_block_arg_im[0].id.stringify %}
            {% block_arg_number = annotation_add_block_arg_im[1] %}
            {% block_return_type = annotation_add_block_arg_im[2] %}
          {% else %}
            {% block_arg_number = nil %}
            {% block_return_type = nil %}
          {% end %}

          {% added_keyword_args = nil %}

          {% if method.annotation(Anyolite::Specialize) && method.annotation(Anyolite::Specialize)[0] %}
            {% added_keyword_args = method.annotation(Anyolite::Specialize)[0] %}
          {% end %}

          {% if annotation_specialize_im && (method.args.stringify == annotation_specialize_im[1].stringify || (method.args.stringify == "[]" && annotation_specialize_im[1] == nil)) %}
            {% added_keyword_args = annotation_specialize_im[2] %}
          {% end %}

          {% without_keywords = false %}

          {% if method.annotation(Anyolite::WrapWithoutKeywords) %}
            {% without_keywords = method.annotation(Anyolite::WrapWithoutKeywords)[0] ? method.annotation(Anyolite::WrapWithoutKeywords)[0] : -1 %}
          {% elsif annotation_without_keyword_im %}
            {% without_keywords = annotation_without_keyword_im[1] ? annotation_without_keyword_im[1] : -1 %}
          {% elsif default_optional_args_to_keyword_args %}
            {% without_keywords = -2 %}
          {% end %}

          {% return_nil = false %}
          {% if method.annotation(Anyolite::ReturnNil) || (annotation_return_nil_im) %}
            {% return_nil = true %}
          {% end %}

          {% store_block_arg = false %}
          {% if method.annotation(Anyolite::StoreBlockArg) || (annotation_store_block_arg_im) %}
            {% store_block_arg = true %}
          {% end %}

          {% force_keyword_arg = false %}
          {% if method.annotation(Anyolite::ForceKeywordArg) || (annotation_force_keyword_arg_im) %}
            {% force_keyword_arg = true %}
          {% end %}

          {% puts "> Processing instance method #{crystal_class}::#{method.name} to #{ruby_name}\n--> Args: #{method.args}" if verbose %}

          {% if method.accepts_block? %}
            {% puts "--> Block arg possible for #{crystal_class}::#{method.name}" if verbose %}
          {% end %}

          # Ignore private and protected methods (can't be called from outside, they'd need to be wrapped for this to work)
          {% if method.name == "dup" || method.name == "clone" %}
            {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion due to copy property)" if verbose %}
          {% elsif crystal_class.resolve.abstract? && method.name == "initialize" %}
            {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion due to abstract class)" if verbose %}
          {% elsif method.visibility != :public && method.name != "initialize" %}
            {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion due to visibility)" if verbose %}
          {% elsif crystal_class != method_source && (later_ancestors ? later_ancestors + [crystal_class] : [crystal_class]).find { |later_ancestor| later_ancestor.resolve? ? later_ancestor.resolve.methods.find { |orig_methods| orig_methods.name == method.name } : [] of Def } %}
            {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion due to finalization)" if verbose %}
          # Ignore rb hooks, to_unsafe and finalize (unless specialized, but this is not recommended)
          {% elsif (method.name.starts_with?("rb_") || method.name == "finalize" || method.name == "to_unsafe") && !has_specialized_method[method.name.stringify] %}
            {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion by default)" if verbose %}
          # Exclude methods if given as arguments
          {% elsif exclusions.includes?(method.name.symbolize) || exclusions.includes?(method.name.stringify) %}
            {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion argument)" if verbose %}
          # Exclude methods which were annotated to be excluded
          {% elsif method.annotation(Anyolite::Exclude) || (annotation_exclude_im && !annotation_include_im && !method.annotation(Anyolite::Include)) %}
            {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion annotation)" if verbose %}
          # Exclude methods which are not the specialized methods
          {% elsif has_specialized_method[method.name.stringify] && !(method.annotation(Anyolite::Specialize) || (annotation_specialize_im && (method.args.stringify == annotation_specialize_im[1].stringify || (method.args.stringify == "[]" && annotation_specialize_im[1] == nil)))) %}
            {% puts "--> Excluding #{crystal_class}::#{method.name} #{method.args} (Specialization)" if verbose %}
          # These methods are a bit tricky and technically require an argument, but usually they are called without one, so we just do it here, too
          {% elsif method.name == "inspect" || method.name == "to_s" || method.name == "hash" %}
            Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", without_keywords: {{without_keywords || (no_keyword_args && !force_keyword_arg)}}, added_keyword_args: [] of NoReturn, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}}, other_source: {{other_source}})
            {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %} 
          # Handle operator methods (including setters) by just transferring the original name into the operator
          # TODO: This might still be a source for potential bugs, so this code might need some reworking in the future
          {% elsif method.name[-1..-1] =~ /\W/ %}
            {% operator = ruby_name %}

            Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", operator: "{{operator}}", without_keywords: {{force_keyword_arg ? false : -1}}, added_keyword_args: {{added_keyword_args}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}}, other_source: {{other_source}})
            {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
          # Handle constructors
          {% elsif method.name == "initialize" && use_enum_methods == false %}
            Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", is_constructor: true, without_keywords: {{without_keywords || (no_keyword_args && !force_keyword_arg)}}, added_keyword_args: {{added_keyword_args}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}}, other_source: {{other_source}})
            {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
          # Handle other instance methods
          {% else %}
            Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", without_keywords: {{without_keywords || (no_keyword_args && !force_keyword_arg)}}, added_keyword_args: {{added_keyword_args}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}}, other_source: {{other_source}})
            {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
          {% end %}

          {% if how_many_times_wrapped[ruby_name.stringify] && how_many_times_wrapped[ruby_name.stringify] > 1 %}
            {% puts "\e[31m> WARNING: Method #{crystal_class}::#{ruby_name}\n--> New arguments: #{method.args}\n--> Wrapped more than once (#{how_many_times_wrapped[ruby_name.stringify]}).\e[0m" %}
          {% end %}
          {% puts "" if verbose %}
        {% end %}
        
        {% if method_source == crystal_class && !crystal_class.resolve.abstract? %}
          # Make sure to add a default constructor if none was specified with Crystal
          {% if !how_many_times_wrapped["initialize"] && !use_enum_methods %}
            Anyolite::Macro.add_default_constructor({{rb_interpreter}}, {{crystal_class}}, {{verbose}})
          {% elsif !how_many_times_wrapped["initialize"] && use_enum_methods %}
          Anyolite::Macro.add_enum_constructor({{rb_interpreter}}, {{crystal_class}}, {{verbose}})
          {% end %}

          {% if !how_many_times_wrapped["inspect"] && use_enum_methods %}
            Anyolite::Macro.add_enum_inspect({{rb_interpreter}}, {{crystal_class}}, {{verbose}})
          {% end %}

          {% all_annotations_exclude_im = crystal_class.resolve.annotations(Anyolite::ExcludeInstanceMethod) + method_source.resolve.annotations(Anyolite::ExcludeInstanceMethod) %}
          {% if all_annotations_exclude_im.find { |element| element[0].id.stringify == "dup" || element[0].id.stringify == "clone" } %}
            Anyolite::RbCore.rb_undef_method({{rb_interpreter}}, Anyolite::RbClassCache.get({{crystal_class}}), "dup")
            Anyolite::RbCore.rb_undef_method({{rb_interpreter}}, Anyolite::RbClassCache.get({{crystal_class}}), "clone")
          {% else %}
            Anyolite::Macro.add_copy_constructor({{rb_interpreter}}, {{crystal_class}}, {{context}}, {{verbose}})
          {% end %}

          {% if wrap_equality_method && !how_many_times_wrapped["=="] %}
            Anyolite::Macro.add_equality_method({{rb_interpreter}}, {{crystal_class}}, {{context}}, {{verbose}})
          {% end %}
        {% end %}
      {% end %}
    end

    macro wrap_all_class_methods(rb_interpreter, crystal_class, exclusions, verbose, context = nil)
      {% has_specialized_method = {} of String => Bool %}

      {% for method in crystal_class.resolve.class.methods %}
        {% all_annotations_specialize_cm = crystal_class.resolve.annotations(Anyolite::SpecializeClassMethod) %}
        {% annotation_specialize_cm = all_annotations_specialize_cm.find { |element| element[0].stringify == method.name.stringify || element[0] == method.name.stringify } %}

        {% if method.annotation(Anyolite::Specialize) %}
          {% has_specialized_method[method.name.stringify] = true %}
        {% end %}

        {% if annotation_specialize_cm %}
          {% has_specialized_method[annotation_specialize_cm[0].id.stringify] = true %}
        {% end %}
      {% end %}

      {% how_many_times_wrapped = {} of String => UInt32 %}

      {% default_optional_args_to_keyword_args = false %}

      {% if !crystal_class.resolve.annotations(Anyolite::DefaultOptionalArgsToKeywordArgs).empty? %}
        {% default_optional_args_to_keyword_args = true %}
      {% else %}
        {% for class_ancestor in crystal_class.resolve.ancestors %}
          {% if !class_ancestor.resolve.annotations(Anyolite::DefaultOptionalArgsToKeywordArgs).empty? %}
            {% default_optional_args_to_keyword_args = true %}
          {% end %}
        {% end %}
      {% end %}

      {% for method, index in crystal_class.resolve.class.methods %}
        {% all_annotations_exclude_cm = crystal_class.resolve.annotations(Anyolite::ExcludeClassMethod) %}
        {% annotation_exclude_cm = all_annotations_exclude_cm.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_specialize_cm = crystal_class.resolve.annotations(Anyolite::SpecializeClassMethod) %}
        {% annotation_specialize_cm = all_annotations_specialize_cm.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_rename_cm = crystal_class.resolve.annotations(Anyolite::RenameClassMethod) %}
        {% annotation_rename_cm = all_annotations_rename_cm.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_without_keywords_cm = crystal_class.resolve.annotations(Anyolite::WrapWithoutKeywordsClassMethod) %}
        {% annotation_without_keyword_cm = all_annotations_without_keywords_cm.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_return_nil_cm = crystal_class.resolve.annotations(Anyolite::ReturnNilClassMethod) %}
        {% annotation_return_nil_cm = all_annotations_return_nil_cm.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_add_block_arg_cm = crystal_class.resolve.annotations(Anyolite::AddBlockArgClassMethod) %}
        {% annotation_add_block_arg_cm = all_annotations_add_block_arg_cm.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_store_block_arg_cm = crystal_class.resolve.annotations(Anyolite::StoreBlockArgClassMethod) %}
        {% annotation_store_block_arg_cm = all_annotations_store_block_arg_cm.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% all_annotations_force_keyword_arg_cm = crystal_class.resolve.annotations(Anyolite::ForceKeywordArgClassMethod) %}
        {% annotation_force_keyword_arg_cm = all_annotations_force_keyword_arg_cm.find { |element| element[0].id.stringify == method.name.stringify } %}

        {% if crystal_class.resolve.annotation(Anyolite::NoKeywordArgs) %}
          {% no_keyword_args = true %}
        {% else %}
          {% no_keyword_args = false %}
        {% end %}

        {% if method.annotation(Anyolite::Rename) %}
          {% ruby_name = method.annotation(Anyolite::Rename)[0].id %}
        {% elsif annotation_rename_cm && method.name.stringify == annotation_rename_cm[0].stringify %}
          {% ruby_name = annotation_rename_cm[1].id %}
        {% else %}
          {% ruby_name = method.name %}
        {% end %}

        {% if method.annotation(Anyolite::AddBlockArg) %}
          {% block_arg_number = method.annotation(Anyolite::AddBlockArg)[0] %}
          {% block_return_type = method.annotation(Anyolite::AddBlockArg)[1] %}
        {% elsif annotation_add_block_arg_cm && method.name.stringify == annotation_add_block_arg_cm[0].stringify %}
          {% block_arg_number = annotation_add_block_arg_cm[1] %}
          {% block_return_type = annotation_add_block_arg_cm[2] %}
        {% else %}
          {% block_arg_number = nil %}
          {% block_return_type = nil %}
        {% end %}

        {% added_keyword_args = nil %}

        {% if method.annotation(Anyolite::Specialize) && method.annotation(Anyolite::Specialize)[1] %}
          {% added_keyword_args = method.annotation(Anyolite::Specialize)[1] %}
        {% end %}

        {% if annotation_specialize_cm && (method.args.stringify == annotation_specialize_cm[1].stringify || (method.args.stringify == "[]" && annotation_specialize_cm[1] == nil)) %}
          {% added_keyword_args = annotation_specialize_cm[2] %}
        {% end %}

        {% without_keywords = false %}

        {% if method.annotation(Anyolite::WrapWithoutKeywords) %}
          {% without_keywords = method.annotation(Anyolite::WrapWithoutKeywords)[0] ? method.annotation(Anyolite::WrapWithoutKeywords)[0] : -1 %}
        {% elsif annotation_without_keyword_cm %}
          {% without_keywords = annotation_without_keyword_cm[1] ? annotation_without_keyword_cm[1] : -1 %}
        {% elsif default_optional_args_to_keyword_args %}
          {% without_keywords = -2 %}
        {% end %}

        {% return_nil = false %}
        {% if method.annotation(Anyolite::ReturnNil) || (annotation_return_nil_cm) %}
          {% return_nil = true %}
        {% end %}

        {% store_block_arg = false %}
        {% if method.annotation(Anyolite::StoreBlockArg) || (annotation_store_block_arg_cm) %}
          {% store_block_arg = true %}
        {% end %}

        {% force_keyword_arg = false %}
        {% if method.annotation(Anyolite::ForceKeywordArg) || (annotation_force_keyword_arg_cm) %}
          {% force_keyword_arg = true %}
        {% end %}

        {% puts "> Processing class method #{crystal_class}::#{method.name} to #{ruby_name}\n--> Args: #{method.args}" if verbose %}

        {% if method.accepts_block? %}
          {% puts "--> Block arg possible for #{crystal_class}::#{method.name}" if verbose %}
        {% end %}
        
        # Ignore private and protected methods (can't be called from outside, they'd need to be wrapped for this to work)
        {% if method.visibility != :public %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion due to visibility)" if verbose %}
        # We already wrapped 'initialize', so we don't need to wrap these
        {% elsif method.name == "allocate" || method.name == "new" %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Allocation method)" if verbose %}
        {% elsif method.name == "parse?" && method.args.stringify == "[string]" %}
          {% operator = ruby_name %}

          Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", operator: "{{operator}}", is_class_method: true, added_keyword_args: [string : String], without_keywords: {{force_keyword_arg ? false : -1}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        {% elsif method.name == "<=" %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Class argument method)" if verbose %}
        # Exclude methods if given as arguments
        {% elsif exclusions.includes?(method.name.symbolize) || exclusions.includes?(method.name.stringify) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion argument)" if verbose %}
        # Exclude methods which were annotated to be excluded
        {% elsif method.annotation(Anyolite::Exclude) || (annotation_exclude_cm) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Exclusion annotation)" if verbose %}
        # Exclude methods which are not the specialized methods
        {% elsif has_specialized_method[method.name.stringify] && !(method.annotation(Anyolite::Specialize) || (annotation_specialize_cm && (method.args.stringify == annotation_specialize_cm[1].stringify || (method.args.stringify == "[]" && annotation_specialize_cm[1] == nil)))) %}
          {% puts "--> Excluding #{crystal_class}::#{method.name} (Specialization)" if verbose %}
        {% elsif method.name[-1..-1] =~ /\W/ %}
          {% operator = ruby_name %}

          Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", operator: "{{operator}}", is_class_method: true, added_keyword_args: {{added_keyword_args}}, without_keywords: {{force_keyword_arg ? false : -1}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        # Handle other class methods
        {% else %}
          Anyolite::Macro.wrap_method_index({{rb_interpreter}}, {{crystal_class}}, {{index}}, "{{ruby_name}}", is_class_method: true, without_keywords: {{without_keywords || (no_keyword_args && !force_keyword_arg)}}, added_keyword_args: {{added_keyword_args}}, context: {{context}}, return_nil: {{return_nil}}, block_arg_number: {{block_arg_number}}, block_return_type: {{block_return_type}}, store_block_arg: {{store_block_arg}})
          {% how_many_times_wrapped[ruby_name.stringify] = how_many_times_wrapped[ruby_name.stringify] ? how_many_times_wrapped[ruby_name.stringify] + 1 : 1 %}
        {% end %}

        {% if how_many_times_wrapped[ruby_name.stringify] && how_many_times_wrapped[ruby_name.stringify] > 1 %}
          {% puts "\e[31m> WARNING: Method #{crystal_class}::#{ruby_name}\n--> New arguments: #{method.args}\n--> Wrapped more than once (#{how_many_times_wrapped[ruby_name.stringify]}).\e[0m" %}
        {% end %}
        {% puts "" if verbose %}
      {% end %}
    end

    macro wrap_all_constants(rb_interpreter, crystal_class, exclusions, verbose = false, overwrite = false, context = nil)
      # TODO: Is the context needed here?

      # NOTE: This check is necessary due to https://github.com/crystal-lang/crystal/issues/5757
      {% if crystal_class.resolve.type_vars.empty? %}
        {% for constant, index in crystal_class.resolve.constants %}
          {% all_annotations_exclude_cm = crystal_class.resolve.annotations(Anyolite::ExcludeConstant) %}
          {% annotation_exclude_cm = all_annotations_exclude_cm.find { |element| element[0].id.stringify == constant.stringify } %}

          {% all_annotations_rename_cm = crystal_class.resolve.annotations(Anyolite::RenameConstant) %}
          {% annotation_rename_cm = all_annotations_rename_cm.find { |element| element[0].id.stringify == constant.stringify } %}

          {% if annotation_rename_cm && constant.stringify == annotation_rename_cm[0].stringify %}
            {% ruby_name = annotation_rename_cm[1].id %}
          {% else %}
            {% ruby_name = constant %}
          {% end %}

          {% puts "> Processing constant #{crystal_class}::#{constant} to #{ruby_name}" if verbose %}
          # Exclude methods which were annotated to be excluded
          {% if exclusions.includes?(constant.symbolize) || exclusions.includes?(constant) %}
            {% puts "--> Excluding #{crystal_class}::#{constant} (Exclusion argument)" if verbose %}
          {% elsif annotation_exclude_cm %}
            {% puts "--> Excluding #{crystal_class}::#{constant} (Exclusion annotation)" if verbose %}
          {% else %}
            Anyolite::Macro.wrap_constant_or_class({{rb_interpreter}}, {{crystal_class}}, "{{ruby_name}}", {{constant}}, overwrite: {{overwrite}}, verbose: {{verbose}})
          {% end %}
          {% puts "" if verbose %}
        {% end %}
      {% end %}
    end
  end
end
