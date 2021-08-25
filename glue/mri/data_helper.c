#include <ruby.h>

extern VALUE rb_define_class_under_helper(void* rb, VALUE superclass, const char* name, VALUE under) {

  rb_define_class_under(under, name, superclass);

}

extern VALUE rb_define_class_helper(void* rb, VALUE superclass, const char* name) {

  rb_define_class(name, superclass);

}

extern VALUE rb_define_module_under_helper(void* rb, VALUE under, const char* name) {

  rb_define_module_under(under, name);

}

extern VALUE rb_define_module_helper(void* rb, const char* name) {

  rb_define_module(name);

}

extern VALUE rb_define_const_helper(void* rb, VALUE under, const char* name, VALUE value) {

  rb_define_const(under, name, value);

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

extern void* get_data_ptr(VALUE ruby_object) {

  return DATA_PTR(ruby_object);

}

extern void set_data_ptr_and_type(VALUE ruby_object, void* data, struct rb_data_type_struct* data_type) {

  TypedData_Wrap_Struct(ruby_object, data_type, data);

}

extern void rb_define_method_helper(void* rb, VALUE ruby_class, const char* name, VALUE (*func)(int argc, VALUE* argv, VALUE self), int aspec) {

  rb_define_method(ruby_class, name, func, -1);

}

extern void rb_define_class_method_helper(void* rb, VALUE ruby_class, const char* name, VALUE (*func)(int argc, VALUE* argv, VALUE self), int aspec) {

  rb_define_module_function(ruby_class, name, func, -1);

}

extern void rb_define_module_function_helper(void* rb, VALUE ruby_module, const char* name, VALUE (*func)(int argc, VALUE* argv, VALUE self), int aspec) {

  rb_define_module_function(ruby_module, name, func, -1);

}

extern VALUE rb_inspect_helper(void* rb, VALUE value) {

  rb_inspect(value);

}