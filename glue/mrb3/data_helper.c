#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/array.h>

extern const mrb_data_type* data_type(mrb_value value) {

    return DATA_TYPE(value);

}

extern void set_instance_tt_as_data(struct RClass* ruby_class) {

    MRB_SET_INSTANCE_TT(ruby_class, MRB_TT_DATA);

}

extern mrb_value new_empty_object(mrb_state* mrb, struct RClass* ruby_class, void* data_ptr, const mrb_data_type* data_type) {

    return mrb_obj_value(mrb_data_object_alloc(mrb, ruby_class, data_ptr, data_type));

}

extern void* get_data_ptr(mrb_value ruby_object) {

    return DATA_PTR(ruby_object);

}

extern void set_data_ptr_and_type(mrb_value ruby_object, void* data, mrb_data_type* data_type) {

    DATA_PTR(ruby_object) = data;
    DATA_TYPE(ruby_object) = data_type;

}

extern struct RClass* get_class_of_obj(mrb_state* mrb, mrb_value object) {

    return mrb_class(mrb, object);

}

extern mrb_sym convert_to_mrb_sym(mrb_state* mrb, const char* str) {

    return mrb_intern_check_cstr(mrb, str);

}

extern size_t array_length(mrb_value array) {

    return ARY_LEN(mrb_ary_ptr(array));

}