#include <mruby.h>
#include <mruby/class.h>

extern struct RClass* get_object_class(mrb_state* mrb) {

    return mrb->object_class;

}

extern mrb_value get_nil_value() {

    return mrb_nil_value();

}

extern mrb_value get_false_value() {

    return mrb_false_value();
  
}

extern mrb_value get_true_value() {

    return mrb_true_value();
  
}

extern mrb_value get_fixnum_value(mrb_int value) {

    return mrb_fixnum_value(value);

}