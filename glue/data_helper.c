#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>

extern const mrb_data_type* data_type(mrb_value value) {

    return DATA_TYPE(value);

}

extern void set_instance_tt_as_data(struct RClass* ruby_class) {

    MRB_SET_INSTANCE_TT(ruby_class, MRB_TT_DATA);

}

extern mrb_value new_empty_object(mrb_state* mrb, struct RClass* ruby_class) {

    return mrb_obj_new(mrb, ruby_class, 0, NULL);

}

extern void* get_data_ptr(mrb_value ruby_object) {

    return DATA_PTR(ruby_object);

}

extern void set_data_ptr_and_type(mrb_value ruby_object, void* data, mrb_data_type* data_type) {

    DATA_PTR(ruby_object) = data;
    DATA_TYPE(ruby_object) = data_type;

}
