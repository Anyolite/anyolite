module Anyolite
  macro link_libraries
    {% build_path = env("ANYOLITE_BUILD_PATH") ? env("ANYOLITE_BUILD_PATH") : "build" %}
    
    {% if flag?(:win32) %}
      {% if flag?(:anyolite_use_msvcrt_lib) %}
        # Not recommended, might be removed in a later release
        @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/mruby/lib/libmruby.lib msvcrt.lib")]
      {% elsif compare_versions(Crystal::VERSION, "1.5.1") >= 0 %}
        # Crystal links against libucrt since 1.5.1
        @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/mruby/lib/libmruby.lib")]
      {% else %}
        @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/mruby/lib/libmruby.lib libucrt.lib ")]
      {% end %}
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mruby/return_functions.obj")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mruby/data_helper.obj")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mruby/script_helper.obj")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mruby/error_helper.obj")]
    {% else %}
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/mruby/lib/libmruby.a")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mruby/return_functions.o")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mruby/data_helper.o")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mruby/script_helper.o")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mruby/error_helper.o")]
    {% end %}
  end

  Anyolite.link_libraries

  lib RbCore
    alias RbFunc = Proc(State*, RbValue, RbValue)
    alias RbDataFunc = Proc(State*, Void*, Nil)

    type State = Void
    type RClass = Void

    alias RbFloat = LibC::Double
    alias RbInt = Int64
    alias RbBool = UInt8
    alias RbSymbol = UInt32

    alias RClassPtr = RClass*

    enum MrbVType
      MRB_TT_FALSE     = 0
      MRB_TT_TRUE
      MRB_TT_SYMBOL
      MRB_TT_UNDEF
      MRB_TT_FREE
      MRB_TT_FLOAT
      MRB_TT_INTEGER
      MRB_TT_CPTR
      MRB_TT_OBJECT
      MRB_TT_CLASS
      MRB_TT_MODULE
      MRB_TT_ICLASS
      MRB_TT_SCLASS
      MRB_TT_PROC
      MRB_TT_ARRAY
      MRB_TT_HASH
      MRB_TT_STRING
      MRB_TT_RANGE
      MRB_TT_EXCEPTION
      MRB_TT_ENV
      MRB_TT_DATA
      MRB_TT_FIBER
      MRB_TT_ISTRUCT
      MRB_TT_BREAK
      MRB_TT_COMPLEX
      MRB_TT_RATIONAL
      MRB_TT_MAXDEFINE
    end

    struct RbValue
      w : LibC::ULongLong
    end

    struct RbDataType
      struct_name : LibC::Char*
      dfree : RbDataFunc
    end

    struct KWArgs
      num : RbInt
      required : RbInt
      table : RbSymbol*
      values : RbValue*
      rest : RbValue*
    end

    struct BytecodeContainer
      content : UInt8*
      size : LibC::SizeT
      error_code : LibC::Int
      result : LibC::Int
    end

    fun rb_open = mrb_open : State*
    fun rb_close = mrb_close(rb : State*)

    fun rb_define_module = mrb_define_module(rb : State*, name : LibC::Char*) : RClassPtr
    fun rb_define_module_under = mrb_define_module_under(rb : State*, under : RClassPtr, name : LibC::Char*) : RClassPtr
    fun rb_define_class = mrb_define_class(rb : State*, name : LibC::Char*, superclass : RClassPtr) : RClassPtr
    fun rb_define_class_under = mrb_define_class_under(rb : State*, under : RClassPtr, name : LibC::Char*, superclass : RClassPtr) : RClassPtr

    fun rb_define_method = mrb_define_method(rb : State*, c : RClassPtr, name : LibC::Char*, func : RbFunc, aspec : UInt32) # TODO: Aspec values
    fun rb_define_class_method = mrb_define_class_method(rb : State*, c : RClassPtr, name : LibC::Char*, func : RbFunc, aspect : UInt32)
    fun rb_define_module_function = mrb_define_module_function(rb : State*, c : RClassPtr, name : LibC::Char*, func : RbFunc, aspect : UInt32)

    fun rb_define_const = mrb_define_const(rb : State*, c : RClassPtr, name : LibC::Char*, val : RbValue)

    fun rb_print_error = mrb_print_error(rb : State*)

    fun rb_raise = mrb_raise(rb : State*, c : RClassPtr, msg : LibC::Char*)
    fun rb_raise_runtime_error = mrb_raise_runtime_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_type_error = mrb_raise_type_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_argument_error = mrb_raise_argument_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_index_error = mrb_raise_index_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_range_error = mrb_raise_range_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_name_error = mrb_raise_name_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_script_error = mrb_raise_script_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_not_implemented_error = mrb_raise_not_implemented_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_key_error = mrb_raise_key_error(rb : State*, msg : LibC::Char*)

    fun rb_get_args = mrb_get_args(rb : State*, format : LibC::Char*, ...) : RbInt

    fun rb_get_argc = mrb_get_argc(rb : State*) : RbInt
    fun rb_get_argv = mrb_get_argv(rb : State*) : RbValue*

    fun rb_yield = mrb_yield(rb : State*, value : RbValue, arg : RbValue) : RbValue
    fun rb_yield_argv = mrb_yield_argv(rb : State*, value : RbValue, argc : RbInt, argv : RbValue*) : RbValue

    fun rb_call_block = mrb_yield(rb : State*, value : RbValue, arg : RbValue) : RbValue
    fun rb_call_block_with_args = mrb_yield_argv(rb : State*, value : RbValue, argc : RbInt, argv : RbValue*) : RbValue

    fun rb_ary_ref = mrb_ary_ref(rb : State*, value : RbValue, pos : RbInt) : RbValue
    fun rb_ary_entry = mrb_ary_entry(value : RbValue, offset : RbInt) : RbValue
    fun array_length(value : RbValue) : LibC::SizeT

    fun rb_ary_new_from_values = mrb_ary_new_from_values(rb : State*, size : RbInt, values : RbValue*) : RbValue

    fun rb_hash_new = mrb_hash_new(rb : State*) : RbValue
    fun rb_hash_set = mrb_hash_set(rb : State*, hash : RbValue, key : RbValue, value : RbValue)
    fun rb_hash_get = mrb_hash_get(rb : State*, hash : RbValue, key : RbValue) : RbValue
    fun rb_hash_keys = mrb_hash_keys(rb : State*, hash : RbValue) : RbValue
    fun rb_hash_size = mrb_hash_size(rb : State*, hash : RbValue) : RbInt

    fun get_nil_value : RbValue
    fun get_false_value : RbValue
    fun get_true_value : RbValue
    fun get_fixnum_value(value : RbInt) : RbValue
    fun get_bool_value(value : RbBool) : RbValue
    fun get_float_value(rb : State*, value : RbFloat) : RbValue
    fun get_string_value(rb : State*, value : LibC::Char*) : RbValue

    fun check_rb_fixnum = check_mrb_fixnum(value : RbValue) : LibC::Int
    fun check_rb_float = check_mrb_float(value : RbValue) : LibC::Int
    fun check_rb_true = check_mrb_true(value : RbValue) : LibC::Int
    fun check_rb_false = check_mrb_false(value : RbValue) : LibC::Int
    fun check_rb_nil = check_mrb_nil(value : RbValue) : LibC::Int
    fun check_rb_undef = check_mrb_undef(value : RbValue) : LibC::Int
    fun check_rb_string = check_mrb_string(value : RbValue) : LibC::Int
    fun check_rb_symbol = check_mrb_symbol(value : RbValue) : LibC::Int
    fun check_rb_array = check_mrb_array(value : RbValue) : LibC::Int
    fun check_rb_hash = check_mrb_hash(value : RbValue) : LibC::Int
    fun check_rb_data = check_mrb_data(value : RbValue) : LibC::Int

    fun get_rb_fixnum = get_mrb_fixnum(value : RbValue) : RbInt
    fun get_rb_float = get_mrb_float(value : RbValue) : RbFloat
    fun get_rb_bool = get_mrb_bool(value : RbValue) : RbBool
    fun get_rb_string = get_mrb_string(rb : State*, value : RbValue) : LibC::Char*

    fun rb_str_to_cstr = mrb_str_to_cstr(rb : State*, value : RbValue) : LibC::Char*

    fun convert_to_rb_sym = convert_to_mrb_sym(rb : State*, value : LibC::Char*) : RbSymbol
    fun get_symbol_value_of_string(rb : State*, value : LibC::Char*) : RbValue

    # Base class, not to be confused with `get_class_of_obj`
    fun get_object_class(rb : State*) : RClassPtr

    fun rb_obj_inspect = mrb_obj_inspect(rb : State*, value : RbValue) : RbValue
    fun rb_any_to_s = mrb_any_to_s(rb : State*, value : RbValue) : RbValue
    fun rb_inspect = mrb_inspect(rb : State*, value : RbValue) : RbValue

    fun rb_gc_register = mrb_gc_register(rb : State*, value : RbValue) : Void
    fun rb_gc_unregister = mrb_gc_unregister(rb : State*, value : RbValue) : Void

    fun rb_class_name = mrb_class_name(rb : State*, class_ptr : RClassPtr) : LibC::Char*

    fun data_type(value : RbValue) : RbDataType*
    fun rb_data_get_ptr = mrb_data_get_ptr(rb : State*, obj : RbValue, type : RbDataType*) : Void*
    fun set_instance_tt_as_data(ruby_class : RClassPtr) : Void
    fun new_empty_object(rb : State*, ruby_class : RClassPtr, data_ptr : Void*, type : RbDataType*) : RbValue
    fun set_data_ptr_and_type(ruby_object : RbValue, data : Void*, type : RbDataType*)
    fun get_data_ptr(ruby_object : RbValue) : Void*

    fun get_rb_obj_value = get_mrb_obj_value(p : RClassPtr) : RbValue

    fun rb_obj_is_kind_of = mrb_obj_is_kind_of(rb : State*, obj : RbValue, c : RClassPtr) : RbBool
    fun get_class_of_obj(rb : State*, obj : RbValue) : RClassPtr

    fun rb_funcall_argv = mrb_funcall_argv(rb : State*, value : RbValue, name : RbSymbol, argc : RbInt, argv : RbValue*) : RbValue
    fun rb_funcall_argv_with_block = mrb_funcall_with_block(rb : State*, value : RbValue, name : RbSymbol, argc : RbInt, argv : RbValue*, block : RbValue) : RbValue

    fun rb_respond_to = mrb_respond_to(rb : State*, obj : RbValue, name : RbSymbol) : RbBool

    fun rb_class_get = mrb_class_get(rb : State*, name : LibC::Char*) : RClassPtr
    fun rb_class_get_under = mrb_class_get_under(rb : State*, under : RClassPtr, name : LibC::Char*) : RClassPtr

    fun rb_class_defined = mrb_class_defined(rb : State*, name : LibC::Char*) : RbBool
    fun rb_class_defined_under = mrb_class_defined_under(rb : State*, under : RClassPtr, name : LibC::Char*) : RbBool

    fun rb_module_get = mrb_module_get(rb : State*, name : LibC::Char*) : RClassPtr
    fun rb_module_get_under = mrb_module_get_under(rb : State*, under : RClassPtr, name : LibC::Char*) : RClassPtr

    fun rb_module_defined = mrb_class_defined(rb : State*, name : LibC::Char*) : RbBool
    fun rb_module_defined_under = mrb_class_defined_under(rb : State*, under : RClassPtr, name : LibC::Char*) : RbBool

    fun rb_iv_set = mrb_iv_set(rb : State*, obj : RbValue, sym : RbSymbol, value : RbValue) : Void
    fun rb_iv_get = mrb_iv_get(rb : State*, obj : RbValue, sym : RbSymbol) : RbValue

    fun rb_cv_set = mrb_cv_set(rb : State*, mod : RbValue, sym : RbSymbol, value : RbValue) : Void
    fun rb_cv_get = mrb_cv_get(rb : State*, mod : RbValue, sym : RbSymbol) : RbValue

    # NOTE: These are differing due to global variable methods by ID being private in MRI
    # NOTE: You should not use globals that often, anyway

    fun rb_gv_set = mrb_gv_set(rb : State*, name : LibC::Char*, value : RbValue) : Void
    fun rb_gv_get = mrb_gv_get(rb : State*, name : LibC::Char*) : RbValue

    fun rb_undef_method = mrb_undef_method(rb : State*, class_ptr : RClassPtr, name : LibC::Char*) : Void
    fun rb_undef_class_method = mrb_undef_class_method(rb : State*, class_ptr : RClassPtr, name : LibC::Char*) : Void

    fun load_script_from_file(rb : State*, filename : LibC::Char*) : RbValue
    fun execute_script_line(rb : State*, str : LibC::Char*) : RbValue
    fun execute_bytecode(rb : State*, bytecode : UInt8*) : RbValue
    fun load_bytecode_from_file(rb : State*, filename : LibC::Char*) : RbValue

    fun transform_script_to_bytecode(filename : LibC::Char*, target_filename : LibC::Char*) : LibC::Int
    fun transform_script_to_bytecode_container(filename : LibC::Char*) : BytecodeContainer
    fun transform_proc_to_bytecode_container(rb : State*, proc_object : RbValue) : BytecodeContainer
    fun free_bytecode_container(container : BytecodeContainer) : Void

    fun rb_fiber_resume = mrb_fiber_resume(rb : State*, fiber : RbValue, argc : RbInt, argv : RbValue*) : RbValue
    fun rb_fiber_yield = mrb_fiber_yield(rb : State*, argc : RbInt, argv : RbValue*) : RbValue
    fun rb_fiber_alive = mrb_fiber_alive_p(rb : State*, fiber : RbValue) : RbValue
  end
end
