#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/string.h>
#include <string.h>

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

extern mrb_value get_bool_value(mrb_bool value) {

    return mrb_bool_value(value);

}

extern mrb_value get_float_value(mrb_state* mrb, mrb_float value) {

    return mrb_float_value(mrb, value);

}

extern mrb_value get_string_value(mrb_state* mrb, char* value) {

    return mrb_str_new(mrb, value, strlen(value));

}

extern int check_mrb_fixnum(mrb_value value) {

    return mrb_integer_p(value);

}

extern int check_mrb_float(mrb_value value) {

    return mrb_float_p(value);

}

extern int check_mrb_true(mrb_value value) {

    return mrb_true_p(value);

}

extern int check_mrb_false(mrb_value value) {

    return mrb_false_p(value);

}

extern int check_mrb_nil(mrb_value value) {

    return mrb_nil_p(value);

}

extern int check_mrb_undef(mrb_value value) {

    return mrb_undef_p(value);

}

extern int check_mrb_string(mrb_value value) {

    return mrb_string_p(value);

}

extern int check_mrb_array(mrb_value value) {   

    return mrb_array_p(value);

}

extern int check_mrb_hash(mrb_value value) {

    return mrb_hash_p(value);

}

extern int check_mrb_data(mrb_value value) {

    return mrb_data_p(value);

}

extern mrb_int get_mrb_fixnum(mrb_value value) {

    return mrb_integer(value);

}

extern mrb_float get_mrb_float(mrb_value value) {

    return mrb_float(value);

}

extern mrb_bool get_mrb_bool(mrb_value value) {

    return mrb_bool(value);

}

extern const char* get_mrb_string(mrb_state* mrb, mrb_value value) {

    return mrb_str_to_cstr(mrb, value);

}
