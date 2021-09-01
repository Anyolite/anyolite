module Anyolite
  macro link_libraries
    {% build_path = env("ANYOLITE_BUILD_PATH") ? env("ANYOLITE_BUILD_PATH") : "build" %}
    
    {% if flag?(:win32) %}
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/mri/lib/libruby-static.lib -lgmp -lcrypt -lz msvcrt.lib Ws2_32.lib")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mri/return_functions.obj -lgmp -lcrypt -lz")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mri/data_helper.obj -lgmp -lcrypt -lz")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mri/script_helper.obj -lgmp -lcrypt -lz")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mri/error_helper.obj -lgmp -lcrypt -lz")]
    {% else %}
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/mri/lib/libruby-static.a -lgmp -lcrypt -lz")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mri/return_functions.o -lgmp -lcrypt -lz")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mri/data_helper.o -lgmp -lcrypt -lz")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mri/script_helper.o -lgmp -lcrypt -lz")]
      @[Link(ldflags: "#{__DIR__}/../../../{{build_path.id}}/glue/mri/error_helper.o -lgmp -lcrypt -lz")]
    {% end %}
  end
  
  Anyolite.link_libraries

  lib RbCore
    alias RbFunc = Proc(RbInt, RbValue*, RbValue, RbValue) # argc, argv, self -> VALUE
    alias RbDataFunc = Proc(Void*, Nil)

    type State = Void

    alias RClassPtr = RbValue

    alias RbFloat = LibC::Double
    alias RbInt = Int64
    alias RbBool = UInt8
    alias RbSymbol = LibC::ULong

    enum MrbVType
      MRB_TT_FALSE = 0
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
      w : LibC::ULong
    end

    struct RbDataType
      struct_name : LibC::Char*
      dmark : RbDataFunc
      dfree : RbDataFunc
      dize : Proc(Void*, LibC::SizeT)
      dcompact : RbDataFunc
      reserved : Void**
      parent : RbDataType*
      data : Void*
      flags : RbValue
    end

    struct KWArgs
      num : UInt32
      required : UInt32
      table : RbSymbol*
      values : RbValue*
      rest : RbValue*
    end

    fun rb_open = open_interpreter : State*
    fun rb_close = close_interpreter(rb : State*)

    fun rb_define_module = rb_define_module_helper(rb : State*, name : LibC::Char*) : RClassPtr
    fun rb_define_module_under = rb_define_module_under_helper(rb : State*, under : RClassPtr, name : LibC::Char*) : RClassPtr
    fun rb_define_class = rb_define_class_helper(rb : State*, name : LibC::Char*, superclass : RClassPtr) : RClassPtr
    fun rb_define_class_under = rb_define_class_under_helper(rb : State*, under : RClassPtr, name : LibC::Char*, superclass : RClassPtr) : RClassPtr

    fun rb_define_method = rb_define_method_helper(rb : State*, c : RClassPtr, name : LibC::Char*, func : RbFunc, aspec : UInt32) # TODO: Aspec values
    fun rb_define_class_method = rb_define_class_method_helper(rb : State*, c : RClassPtr, name : LibC::Char*, func : RbFunc, aspect : UInt32)
    fun rb_define_module_function = rb_define_module_function_helper(rb : State*, c : RClassPtr, name : LibC::Char*, func : RbFunc, aspect : UInt32)

    fun rb_define_const = rb_define_const_helper(rb : State*, c : RClassPtr, name : LibC::Char*, val : RbValue)

    # UNUSED
    # fun rb_print_error = mrb_print_error(rb : State*)

    fun rb_raise = rb_raise_helper(rb : State*, c : RClassPtr, msg : LibC::Char*)
    fun rb_raise_runtime_error = rb_raise_runtime_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_type_error = rb_raise_type_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_argument_error = rb_raise_argument_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_index_error = rb_raise_index_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_range_error = rb_raise_range_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_name_error = rb_raise_name_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_script_error = rb_raise_script_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_not_implemented_error = rb_raise_not_implemented_error(rb : State*, msg : LibC::Char*)
    fun rb_raise_key_error = rb_raise_key_error(rb : State*, msg : LibC::Char*)

    fun rb_get_args = rb_scan_args(argc : RbInt, argv : RbValue*, format : LibC::Char*, ...) : RbInt
    
    # UNUSED
    # fun rb_get_argc = mrb_get_argc(rb : State*) : RbInt
    # fun rb_get_argv = mrb_get_argv(rb : State*) : RbValue*

    fun rb_yield = rb_yield_helper(rb : State*, value : RbValue, arg : RbValue) : RbValue
    fun rb_yield_argv = rb_yield_argv_helper(rb : State*, value : RbValue, argc : RbInt, argv : RbValue*) : RbValue

    fun rb_call_block = rb_yield_helper(rb : State*, value : RbValue, arg : RbValue) : RbValue
    fun rb_call_block_with_args = rb_call_block_with_args_helper(rb : State*, value : RbValue, argc : RbInt, argv : RbValue*) : RbValue

    fun rb_ary_ref = rb_ary_ref_helper(rb : State*, value : RbValue, pos : RbInt) : RbValue
    fun rb_ary_entry(value : RbValue, offset : RbInt) : RbValue
    fun array_length = rb_ary_length_helper(value : RbValue) : LibC::SizeT

    fun rb_ary_new_from_values = rb_ary_new_from_values_helper(rb : State*, size : RbInt, values : RbValue*) : RbValue

    fun rb_hash_new = rb_hash_new_helper(rb : State*) : RbValue
    fun rb_hash_set = rb_hash_set_helper(rb : State*, hash : RbValue, key : RbValue, value : RbValue)
    fun rb_hash_get = rb_hash_get_helper(rb : State*, hash : RbValue, key : RbValue) : RbValue
    fun rb_hash_keys = rb_hash_keys_helper(rb : State*, hash : RbValue) : RbValue
    fun rb_hash_size = rb_hash_size_helper(rb : State*, hash : RbValue) : RbInt

    fun get_nil_value : RbValue
    fun get_false_value : RbValue
    fun get_true_value : RbValue
    fun get_fixnum_value(value : RbInt) : RbValue
    fun get_bool_value(value : RbBool) : RbValue
    fun get_float_value(rb : State*, value : RbFloat) : RbValue
    fun get_string_value(rb : State*, value : LibC::Char*) : RbValue

    fun check_rb_fixnum(value : RbValue) : LibC::Int
    fun check_rb_float(value : RbValue) : LibC::Int
    fun check_rb_true (value : RbValue) : LibC::Int
    fun check_rb_false(value : RbValue) : LibC::Int
    fun check_rb_nil(value : RbValue) : LibC::Int
    fun check_rb_undef(value : RbValue) : LibC::Int
    fun check_rb_string(value : RbValue) : LibC::Int
    fun check_rb_symbol(value : RbValue) : LibC::Int
    fun check_rb_array(value : RbValue) : LibC::Int
    fun check_rb_hash(value : RbValue) : LibC::Int
    fun check_rb_data(value : RbValue) : LibC::Int

    fun get_rb_fixnum(value : RbValue) : RbInt 
    fun get_rb_float(value : RbValue) : RbFloat
    fun get_rb_bool(value : RbValue) : RbBool
    fun get_rb_string(rb : State*, value : RbValue) : LibC::Char*

    fun rb_str_to_cstr(rb : State*, value : RbValue) : LibC::Char*

    fun convert_to_rb_sym = convert_to_rb_sym_helper(rb : State*, value : LibC::Char*) : RbSymbol
    fun get_symbol_value_of_string(rb : State*, value : LibC::Char*) : RbValue

    # Base class, not to be confused with `get_class_of_obj`
    fun get_object_class(rb : State*) : RClassPtr

    # UNUSED
    # fun rb_obj_inspect = mrb_obj_inspect(rb : State*, value : RbValue) : RbValue
    # fun rb_any_to_s = mrb_any_to_s(rb : State*, value : RbValue) : RbValue

    fun rb_inspect = rb_inspect_helper(rb : State*, value : RbValue) : RbValue

    fun rb_gc_register = rb_gc_register_helper(rb : State*, value : RbValue) : Void
    fun rb_gc_unregister = rb_gc_unregister_helper(rb : State*, value : RbValue) : Void

    fun rb_class_name = rb_class_name_helper(rb : State*, class_ptr : RClassPtr) : LibC::Char*

    # UNUSED
    # fun data_type(value : RbValue) : RbDataType*
    # fun rb_data_get_ptr = mrb_data_get_ptr(rb : State*, obj : RbValue, type : RbDataType*) : Void*

    fun set_instance_tt_as_data(ruby_class : RClassPtr) : Void
    fun new_empty_object(rb : State*, ruby_class : RClassPtr, data_ptr : Void*, type : RbDataType*) : RbValue
    fun set_data_ptr_and_type(ruby_object : RbValue, data : Void*, type : RbDataType*)
    fun get_data_ptr(ruby_object : RbValue) : Void*

    fun get_rb_obj_value(p : RClassPtr) : RbValue

    fun rb_obj_is_kind_of = rb_obj_is_kind_of_helper(rb : State*, obj : RbValue, c : RClassPtr) : RbBool
    fun get_class_of_obj = rb_obj_class_helper(rb : State*, obj : RbValue) : RClassPtr

    fun rb_funcall_argv = rb_funcall_argv_helper(rb : State*, value : RbValue, name : RbSymbol, argc : RbInt, argv : RbValue*) : RbValue
    fun rb_funcall_argv_with_block = rb_funcall_argv_with_block_helper(rb : State*, value : RbValue, name : RbSymbol, argc : RbInt, argv : RbValue*, block : RbValue) : RbValue

    fun rb_respond_to = rb_respond_to_helper(rb : State*, obj : RbValue, name : RbSymbol) : RbBool

    fun rb_iv_set = rb_iv_set_helper(rb : State*, obj : RbValue, sym : RbSymbol, value : RbValue) : Void
    fun rb_iv_get = rb_iv_get_helper(rb : State*, obj : RbValue, sym : RbSymbol) : RbValue

    fun rb_cv_set = rb_cv_set_helper(rb : State*, mod : RbValue, sym : RbSymbol, value : RbValue) : Void
    fun rb_cv_get = rb_cv_get_helper(rb : State*, mod : RbValue, sym : RbSymbol) : RbValue

    fun rb_gv_set = rb_gv_set_helper(rb : State*, name : LibC::Char*, value : RbValue) : Void
    fun rb_gv_get = rb_gv_get_helper(rb : State*, name : LibC::Char*) : RbValue

    fun load_script_from_file(rb : State*, filename : LibC::Char*) : Void

    # TODO
    # fun execute_script_line(rb : State*, str : LibC::Char*) : RbValue

    # UNUSED
    # fun execute_bytecode(rb : State*, bytecode : UInt8*) : RbValue
    # fun load_bytecode_from_file(rb : State*, filename : LibC::Char*) : RbValue
    # fun transform_script_to_bytecode(filename : LibC::Char*, target_filename : LibC::Char*) : LibC::Int
  end
end
