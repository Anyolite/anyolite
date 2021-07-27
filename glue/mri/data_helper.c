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

//! TODO: rb_get_args