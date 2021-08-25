#include <ruby.h>

extern VALUE get_object_class(void* rb) {

    return rb_cObject;

}

extern VALUE get_nil_value() {

    return Qnil;

}

extern VALUE get_false_value() {

    return Qfalse;
  
}

extern VALUE get_true_value() {

    return Qtrue;
  
}

extern VALUE get_fixnum_value(int value) {

    return INT2FIX(value);

}

extern VALUE get_bool_value(bool value) {

    return (value ? Qtrue : Qfalse);

}

extern VALUE get_float_value(void* mrb, double value) {

    return DBL2NUM(value);

}

extern VALUE get_string_value(void* mrb, char* value) {

    return rb_str_new(value, strlen(value));

}

extern VALUE get_symbol_value_of_string(void* mrb, char* value) {

    ID sym = rb_intern(value);
    return ID2SYM(sym);

}

extern int check_rb_fixnum(VALUE value) {

    return FIXNUM_P(value);

}

extern int check_rb_float(VALUE value) {

    return RB_FLOAT_TYPE_P(value);

}

extern int check_rb_true(VALUE value) {

    return (value == Qtrue);

}

extern int check_rb_false(VALUE value) {

    return (value == Qfalse);

}

extern int check_rb_nil(VALUE value) {

    return NIL_P(value);

}

extern int check_rb_undef(VALUE value) {

    return RB_TYPE_P(value, T_UNDEF);

}

extern int check_rb_string(VALUE value) {

    return RB_TYPE_P(value, T_STRING);

}

extern int check_rb_symbol(VALUE value) {

    return RB_TYPE_P(value, T_SYMBOL);

}

extern int check_rb_array(VALUE value) {   

    return RB_TYPE_P(value, T_ARRAY);

}

extern int check_rb_hash(VALUE value) {

    return RB_TYPE_P(value, T_HASH);

}

extern int check_rb_data(VALUE value) {

    return RB_TYPE_P(value, T_DATA);

}

extern int get_rb_fixnum(VALUE value) {

    return FIX2INT(value);

}

extern double get_rb_float(VALUE value) {

    return NUM2DBL(value);

}

extern bool get_rb_bool(VALUE value) {

    return (value != Qfalse);

}

extern const char* get_rb_string(void* mrb, VALUE value) {

    return rb_string_value_cstr(&value);

}
