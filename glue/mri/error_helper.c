#include <ruby.h>

extern void rb_raise_runtime_error(void* rb, const char* msg) {

  rb_raise(rb_eRuntimeError, msg);

}

extern void rb_raise_type_error(void* rb, const char* msg) {

  rb_raise(rb_eTypeError, msg);

}

extern void rb_raise_argument_error(void* rb, const char* msg) {

  rb_raise(rb_eArgError, msg);

}

extern void rb_raise_index_error(void* rb, const char* msg) {

  rb_raise(rb_eIndexError, msg);

}

extern void rb_raise_range_error(void* rb, const char* msg) {

  rb_raise(rb_eRangeError, msg);

}

extern void rb_raise_name_error(void* rb, const char* msg) {

  rb_raise(rb_eNameError, msg);

}

extern void rb_raise_script_error(void* rb, const char* msg) {

  rb_raise(rb_eScriptError, msg);

}

extern void rb_raise_not_implemented_error(void* rb, const char* msg) {

  rb_raise(rb_eNotImpError, msg);

}

extern void rb_raise_key_error(void* rb, const char* msg) {

  rb_raise(rb_eKeyError, msg);

}

extern void rb_raise_helper(void* rb, VALUE exc, const char* msg) {

  rb_raise(exc, msg);

}

extern void clear_last_rb_error(void* rb) {

  rb_set_errinfo(Qnil);

}

extern VALUE get_last_rb_error(void* rb) {

  return rb_errinfo();

}
