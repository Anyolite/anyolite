@[Link(ldflags: "#{__DIR__}/build/mruby/lib/libmruby.a -DMRB_INT64")]
@[Link(ldflags: "#{__DIR__}/build/glue/return_functions.o -DMRB_INT64")]

lib MRubyInternal

    type MrbState = Void
    type RClass = Void

    alias MrbFloat = LibC::Float
    alias MrbInt = Int64
    alias MrbBool = UInt8
    type MrbSymbol = UInt32

    union MrbValueUnion
        value_float : MrbFloat
        value_pointer : Void*
        value_int : MrbInt
        value_sym : MrbSymbol
    end

    enum MrbVType
        MRB_TT_FALSE = 0
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
        MRB_TT_FILE
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

    fun mrb_open() : MrbState*
    fun mrb_load_string(mrb : MrbState*, s : LibC::Char*)
    fun mrb_close(mrb : MrbState*)
    fun mrb_define_class(mrb : MrbState*, name : LibC::Char*, super : RClass*) : RClass*
    fun mrb_define_method(mrb : MrbState*, c : RClass*, name : LibC::Char*, func : MrbState*, MrbValue -> MrbValue, aspec : UInt32)

    fun get_nil_value() : MrbValue
    fun get_false_value() : MrbValue
    fun get_true_value() : MrbValue
    fun get_fixnum_value(value : MrbInt) : MrbValue
    fun get_bool_value(value : MrbBool) : MrbValue
    fun get_float_value(mrb: MrbState*, value : MrbFloat) : MrbValue

    fun get_object_class(mrb : MrbState*) : RClass*

end

alias MrbFunc = Proc(MRubyInternal::MrbState*, MRubyInternal::MrbValue, MRubyInternal::MrbValue)

class MrbState

    @mrb_ptr : MRubyInternal::MrbState*

    def self.create
        mrb = self.new
        yield mrb
        mrb.close
    end

    def initialize
        @mrb_ptr = MRubyInternal.mrb_open()
    end

    def close
        MRubyInternal.mrb_close(@mrb_ptr)
    end

    def to_unsafe
        return @mrb_ptr
    end

    def load_string(str : String)
        MRubyInternal.mrb_load_string(@mrb_ptr, str)
    end

    def define_method(name : String, c : MrbClass, proc : MrbFunc)
        MRubyInternal.mrb_define_method(@mrb_ptr, c, name, proc, 0)
    end

end

class MrbClass

    def initialize(@mrb : MrbState, @name : String, superclass : MrbClass | Nil = nil)
        actual_superclass = superclass ? superclass : MRubyInternal.get_object_class(@mrb)
        @class_ptr = MRubyInternal.mrb_define_class(@mrb, @name, actual_superclass)
    end

    def to_unsafe
        return @class_ptr
    end

end

module MrbCast

    def self.return_nil
        return MRubyInternal.get_nil_value
    end

    def self.return_true
        return MRubyInternal.get_true_value
    end

    def self.return_false
        return MRubyInternal.get_false_value
    end

    def self.return_fixnum(value)
        return MRubyInternal.get_fixnum_value(value)
    end

    def self.return_bool(value)
        return MRubyInternal.get_bool_value(value ? 1 : 0)
    end

    def self.return_float(mrb, value)
        return MRubyInternal.get_float_value(mrb, value)
    end

end

MrbState.create do |mrb|

    test_class = MrbClass.new(mrb, "Test")

    p = MrbFunc.new do |mrb, self|
        MrbCast.return_bool(false)
    end

    mrb.define_method("foo", test_class, p)

    mrb.load_string("a = Test.new.foo; puts a")

end