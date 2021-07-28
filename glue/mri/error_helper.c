#include <ruby.h>

extern void rb_raise_runtime_error(void* mrb, const char* msg) {

  rb_raise(rb_eRuntimeError, msg);

}

extern void rb_raise_type_error(void* mrb, const char* msg) {

  rb_raise(rb_eTypeError, msg);

}

extern void rb_raise_argument_error(void* mrb, const char* msg) {

  rb_raise(rb_eArgError, msg);

}

extern void rb_raise_index_error(void* mrb, const char* msg) {

  rb_raise(rb_eIndexError, msg);

}

extern void rb_raise_range_error(void* mrb, const char* msg) {

  rb_raise(rb_eRangeError, msg);

}

extern void rb_raise_name_error(void* mrb, const char* msg) {

  rb_raise(rb_eNameError, msg);

}

extern void rb_raise_script_error(void* mrb, const char* msg) {

  rb_raise(rb_eScriptError, msg);

}

extern void rb_raise_not_implemented_error(void* mrb, const char* msg) {

  rb_raise(rb_eNotImpError, msg);

}

extern void rb_raise_key_error(void* mrb, const char* msg) {

  rb_raise(rb_eKeyError, msg);

}
