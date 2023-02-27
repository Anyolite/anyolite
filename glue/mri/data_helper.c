#include <ruby.h>

extern VALUE rb_define_class_under_helper(void* rb, VALUE under, const char* name, VALUE superclass) {

  rb_define_class_under(under, name, superclass);

}

extern VALUE rb_define_class_helper(void* rb, const char* name, VALUE superclass) {

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

//! About the following method...
//! It is highly hacky and just modifies a newly creates Ruby object, but that is okay.
//! It tells the Ruby GC that this object is a pointer and how to free it.
//! Crystal owns the pointer, so Ruby does not have to do anything else besides calling dfree.

extern void set_data_ptr_and_type(VALUE ruby_object, void* data, struct rb_data_type_struct* data_type) {

  DATA_PTR(ruby_object) = data;
  RDATA(ruby_object)->basic.flags = T_DATA;
  RDATA(ruby_object)->dmark = data_type->function.dmark;
  RDATA(ruby_object)->dfree = data_type->function.dfree;

}

extern VALUE new_empty_object(void* rb, VALUE ruby_class, void* data_ptr, struct rb_data_type_struct* data_type) {

  rb_undef_alloc_func(ruby_class);
  rb_data_object_wrap(ruby_class, data_ptr, data_type->function.dmark, data_type->function.dfree);

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

extern VALUE rb_hash_new_helper(void* rb) {

  rb_hash_new();

}

extern void rb_hash_set_helper(void* rb, VALUE hash, VALUE key, VALUE value) {

  rb_hash_aset(hash, key, value);

}

extern VALUE rb_hash_get_helper(void* rb, VALUE hash, VALUE key) {

  rb_hash_aref(hash, key);

}

extern VALUE rb_hash_keys_helper(void* rb, VALUE hash) {

  //! NOTE: For some reason rb_hash_keys is not marked as extern, so for now this is a workaround
  rb_funcall(hash, rb_intern("keys"), 0);

}

extern int rb_hash_size_helper(void* rb, VALUE hash) {

  rb_hash_size(hash);

}

extern VALUE convert_to_rb_sym_helper(void* rb, const char* value) {

  rb_intern(value);

}

extern VALUE rb_ary_ref_helper(void* rb, VALUE ary, int pos) {

  rb_ary_entry(ary, pos);

}

extern size_t rb_ary_length_helper(VALUE ary) {

  size_t return_value = (size_t) RARRAY_LEN(ary);
  return_value;

}

extern VALUE rb_ary_new_from_values_helper(void* rb, int size, VALUE* values) {

  rb_ary_new_from_values(size, values);

}

extern void rb_gc_register_helper(void* rb, VALUE value) {

  rb_gc_register_address(&value);

}

extern void rb_gc_unregister_helper(void* rb, VALUE value) {

  rb_gc_unregister_address(&value);
  
}

extern VALUE rb_yield_helper(void* rb, VALUE value, VALUE arg) {

  rb_yield(arg);

}

extern VALUE rb_yield_argv_helper(void* rb, VALUE value, int argc, VALUE* argv) {

  rb_yield_values2(argc, argv);

}

extern VALUE rb_call_block_helper(void* rb, VALUE value, VALUE arg) {

  rb_proc_call(value, rb_ary_new_from_values(1, &arg));

}

extern VALUE rb_call_block_with_args_helper(void* rb, VALUE value, int argc, VALUE* argv) {

  rb_proc_call(value, rb_ary_new_from_values(argc, argv));

}

extern bool rb_respond_to_helper(void* rb, VALUE obj, ID name) {

  rb_respond_to(obj, name);

}

extern VALUE get_rb_obj_value(VALUE obj) {

  return obj;

}

extern VALUE rb_funcall_argv_helper(void *rb, VALUE value, ID name, int argc, VALUE* argv) {

  rb_funcallv(value, name, argc, argv);

}

extern VALUE rb_funcall_argv_with_block_helper(void *rb, VALUE value, ID name, int argc, VALUE* argv, VALUE block) {

  rb_funcall_with_block(value, name, argc, argv, block);

}

extern VALUE rb_iv_get_helper(void* rb, VALUE obj, ID sym) {

  rb_ivar_get(obj, sym);

}

extern void rb_iv_set_helper(void* rb, VALUE obj, ID sym, VALUE value) {
  
  rb_ivar_set(obj, sym, value);

}

extern VALUE rb_cv_get_helper(void* rb, VALUE mod, ID sym) {

  rb_cvar_get(mod, sym);
  
}

extern void rb_cv_set_helper(void* rb, VALUE mod, ID sym, VALUE value) {

  rb_cvar_set(mod, sym, value);
  
}

extern VALUE rb_gv_get_helper(void* rb, const char* name) {

  rb_gv_get(name);
  
}

extern void rb_gv_set_helper(void* rb, const char* name, VALUE value) {

  rb_gv_set(name, value);
  
}

extern bool does_constant_exist_under(void* rb, VALUE under, const char* name) {

  rb_const_defined_at(under, rb_intern(name)) == Qtrue ? 1 : 0;

}

extern bool does_constant_exist(void* rb, const char* name) {

  rb_const_defined(rb_cObject, rb_intern(name)) == Qtrue ? 1 : 0;

}

extern VALUE get_constant_under(void* rb, VALUE under, const char* name) {

  rb_const_get_at(under, rb_intern(name));

}

extern VALUE get_constant(void* rb, const char* name) {

  rb_const_get(rb_cObject, rb_intern(name));

}

extern VALUE rb_undef_method_helper(void* rb, VALUE mod, const char* name) {

  rb_undef_method(mod, name);

}
