#include <mruby.h>

extern void mrb_raise_argument_error(mrb_state* mrb, const char* msg) {
  mrb_raise(mrb, E_ARGUMENT_ERROR, msg);
}