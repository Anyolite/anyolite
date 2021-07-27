#include <mruby.h>

extern void mrb_raise_runtime_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_RUNTIME_ERROR, msg);

}

extern void mrb_raise_type_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_TYPE_ERROR, msg);

}

extern void mrb_raise_argument_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_ARGUMENT_ERROR, msg);

}

extern void mrb_raise_index_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_INDEX_ERROR, msg);

}

extern void mrb_raise_range_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_RANGE_ERROR, msg);

}

extern void mrb_raise_name_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_NAME_ERROR, msg);

}

extern void mrb_raise_script_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_SCRIPT_ERROR, msg);

}

extern void mrb_raise_not_implemented_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_NOTIMP_ERROR, msg);

}

extern void mrb_raise_key_error(mrb_state* mrb, const char* msg) {

  mrb_raise(mrb, E_KEY_ERROR, msg);

}
