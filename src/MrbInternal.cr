{% if flag?(:win32) %}
  @[Link(ldflags: "#{__DIR__}/../build/mruby/lib/libmruby.lib -DMRB_INT64 msvcrt.lib Ws2_32.lib")]
  @[Link(ldflags: "#{__DIR__}/../build/glue/return_functions.obj -DMRB_INT64")]
  @[Link(ldflags: "#{__DIR__}/../build/glue/data_helper.obj -DMRB_INT64")]
  @[Link(ldflags: "#{__DIR__}/../build/glue/script_helper.obj -DMRB_INT64")]
  @[Link(ldflags: "#{__DIR__}/../build/glue/error_helper.obj -DMRB_INT64")]
{% else %}
  @[Link(ldflags: "#{__DIR__}/../build/mruby/lib/libmruby.a -DMRB_INT64")]
  @[Link(ldflags: "#{__DIR__}/../build/glue/return_functions.o -DMRB_INT64")]
  @[Link(ldflags: "#{__DIR__}/../build/glue/data_helper.o -DMRB_INT64")]
  @[Link(ldflags: "#{__DIR__}/../build/glue/script_helper.o -DMRB_INT64")]
  @[Link(ldflags: "#{__DIR__}/../build/glue/error_helper.o -DMRB_INT64")]
{% end %}

lib MrbInternal
  type MrbState = Void
  type RClass = Void
  type File = Void

  alias MrbFloat = LibC::Float
  alias MrbInt = Int64
  alias MrbBool = UInt8
  alias MrbSymbol = UInt32

  union MrbValueUnion
    value_float : MrbFloat
    value_pointer : Void*
    value_int : MrbInt
    value_sym : MrbSymbol
  end

  enum MrbVType
    MRB_TT_FALSE     = 0
    MRB_TT_TRUE
    MRB_TT_FLOAT
    MRB_TT_FIXNUM
    MRB_TT_SYMBOL
    MRB_TT_UNDEF
    MRB_TT_CPTR
    MRB_TT_FREE
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
    MRB_TT_MAXDEFINE
  end

  struct MrbValue
    value : MrbValueUnion
    tt : MrbVType
  end

  struct MrbDataType
    struct_name : LibC::Char*
    dfree : MrbState*, Void* -> Void
  end

  struct KWArgs
    num : UInt32
    values : MrbValue*
    table : LibC::Char**
    required : UInt32
    rest : MrbValue*
  end

  fun mrb_open : MrbState*
  fun mrb_close(mrb : MrbState*)

  fun mrb_define_module(mrb : MrbState*, name : LibC::Char*) : RClass*
  fun mrb_define_module_under(mrb : MrbState*, under : RClass*, name : LibC::Char*) : RClass*
  fun mrb_define_class(mrb : MrbState*, name : LibC::Char*, superclass : RClass*) : RClass*
  fun mrb_define_class_under(mrb : MrbState*, under : RClass*, name : LibC::Char*, superclass : RClass*) : RClass*

  fun mrb_define_method(mrb : MrbState*, c : RClass*, name : LibC::Char*, func : MrbState*, MrbValue -> MrbValue, aspec : UInt32) # TODO: Aspec values
  fun mrb_define_class_method(mrb : MrbState*, c : RClass*, name : LibC::Char*, func : MrbState*, MrbValue -> MrbValue, aspect : UInt32)
  fun mrb_define_module_function(mrb : MrbState*, c : RClass*, name : LibC::Char*, func : MrbState*, MrbValue -> MrbValue, aspect : UInt32)

  fun mrb_define_const(mrb : MrbState*, c : RClass*, name : LibC::Char*, val : MrbValue)

  fun mrb_print_error(mrb : MrbState*)

  fun mrb_raise(mrb : MrbState*, c : RClass*, msg : LibC::Char*)
  fun mrb_raise_argument_error(mrb : MrbState*, msg : LibC::Char*)

  fun mrb_get_args(mrb : MrbState*, format : LibC::Char*, ...) : MrbInt

  fun get_nil_value : MrbValue
  fun get_false_value : MrbValue
  fun get_true_value : MrbValue
  fun get_fixnum_value(value : MrbInt) : MrbValue
  fun get_bool_value(value : MrbBool) : MrbValue
  fun get_float_value(mrb : MrbState*, value : MrbFloat) : MrbValue
  fun get_string_value(mrb : MrbState*, value : LibC::Char*) : MrbValue

  fun check_mrb_fixnum(value : MrbValue) : LibC::Int
  fun check_mrb_float(value : MrbValue) : LibC::Int
  fun check_mrb_true(value : MrbValue) : LibC::Int
  fun check_mrb_false(value : MrbValue) : LibC::Int
  fun check_mrb_nil(value : MrbValue) : LibC::Int
  fun check_mrb_undef(value : MrbValue) : LibC::Int
  fun check_mrb_string(value : MrbValue) : LibC::Int
  fun check_mrb_data(value : MrbValue) : LibC::Int

  fun get_mrb_fixnum(value : MrbValue) : MrbInt 
  fun get_mrb_float(value : MrbValue) : MrbFloat
  fun get_mrb_bool(value : MrbValue) : MrbBool
  fun get_mrb_string(mrb : MrbState*, value : MrbValue) : LibC::Char*

  fun mrb_str_to_cstr(mrb : MrbState*, value : MrbValue) : LibC::Char*

  # Base class, not to be confused with `get_class_of_obj`
  fun get_object_class(mrb : MrbState*) : RClass*

  fun data_type(value : MrbValue) : MrbDataType*
  fun mrb_data_get_ptr(mrb : MrbState*, obj : MrbValue, type : MrbDataType*) : Void*
  fun set_instance_tt_as_data(ruby_class : RClass*) : Void
  fun new_empty_object(mrb : MrbState*, ruby_class : RClass*, data_ptr : Void*, type : MrbDataType*) : MrbValue
  fun set_data_ptr_and_type(ruby_object : MrbValue, data : Void*, type : MrbDataType*)
  fun get_data_ptr(ruby_object : MrbValue) : Void*

  fun mrb_obj_is_kind_of(mrb : MrbState*, obj : MrbValue, c : RClass*) : MrbBool
  fun get_class_of_obj(mrb : MrbState*, obj : MrbValue) : RClass*

  fun load_script_from_file(mrb : MrbState*, filename : LibC::Char*) : MrbValue
  fun execute_script_line(mrb : MrbState*, str : LibC::Char*) : MrbValue
end
