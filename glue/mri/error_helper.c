#include <ruby.h>

extern void rb_raise_runtime_error(void* rb, const char* msg) {

  rb_raise(rb_eRuntimeError, "%s", msg);

}

extern void rb_raise_type_error(void* rb, const char* msg) {

  rb_raise(rb_eTypeError, "%s", msg);

}

extern void rb_raise_argument_error(void* rb, const char* msg) {

  rb_raise(rb_eArgError, "%s", msg);

}

extern void rb_raise_index_error(void* rb, const char* msg) {

  rb_raise(rb_eIndexError, "%s", msg);

}

extern void rb_raise_range_error(void* rb, const char* msg) {

  rb_raise(rb_eRangeError, "%s", msg);

}

extern void rb_raise_name_error(void* rb, const char* msg) {

  rb_raise(rb_eNameError, "%s", msg);

}

extern void rb_raise_script_error(void* rb, const char* msg) {

  rb_raise(rb_eScriptError, "%s", msg);

}

extern void rb_raise_not_implemented_error(void* rb, const char* msg) {

  rb_raise(rb_eNotImpError, "%s", msg);

}

extern void rb_raise_key_error(void* rb, const char* msg) {

  rb_raise(rb_eKeyError, "%s", msg);

}

extern void rb_raise_helper(void* rb, VALUE exc, const char* msg) {

  rb_raise(exc, "%s", msg);

}

extern void clear_last_rb_error(void* rb) {

  rb_set_errinfo(Qnil);

}

extern VALUE get_last_rb_error(void* rb) {

  return rb_errinfo();

}
