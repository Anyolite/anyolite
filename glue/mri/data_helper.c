#include "ruby.h"

extern VALUE rb_define_class_under_helper(void* rb, VALUE superclass, const char* name, VALUE under) {

  rb_define_class_under(under, name, superclass);

}

extern VALUE rb_define_class_helper(void* rb, VALUE superclass, const char* name) {

  rb_define_class(name, superclass);

}

extern void set_instance_tt_as_data(VALUE ruby_class) {

  //! TODO: Is this function required?
  //MRB_SET_INSTANCE_TT(ruby_class, MRB_TT_DATA);

}

extern bool rb_obj_is_kind_of_helper(void* rb, VALUE object, VALUE ruby_class) {

  rb_obj_is_kind_of(object, ruby_class) == Qtrue ? true : false;

}

extern VALUE rb_obj_class_helper(void* rb, VALUE object) {

  rb_obj_class(object);

}

extern const char* rb_class_name_helper(void* rb, VALUE ruby_class) {

  VALUE class_name_value = rb_class_name(ruby_class);
  rb_string_value_cstr(&class_name_value);

}