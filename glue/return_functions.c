#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
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

//! TODO: Put it in separate files

extern const mrb_data_type* data_type(mrb_value value) {

    return DATA_TYPE(value);

}

extern void set_instance_tt_as_data(struct RClass* ruby_class) {

    MRB_SET_INSTANCE_TT(ruby_class, MRB_TT_DATA);

}

extern mrb_value new_empty_object(mrb_state* mrb, struct RClass* ruby_class) {

    return mrb_obj_new(mrb, ruby_class, 0, NULL);

}

static void do_nothing(mrb_state* mrb, void* data) {

    printf("Ruby destructor called\n");

}

extern void set_data_ptr_and_type(mrb_value* ruby_object, void* data) {

    static const mrb_data_type data_type = {
        "test", do_nothing
    };

    DATA_PTR(*ruby_object) = data;
    DATA_TYPE(*ruby_object) = &data_type;

}