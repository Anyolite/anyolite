module Anyolite
  module Macro
    macro allocate_constructed_object(crystal_class, obj, new_obj)
      # Call initializer method if available
      if new_obj.responds_to?(:rb_initialize)
        new_obj.rb_initialize(rb)
      end

      # Allocate memory so we do not lose this object
      if {{crystal_class}} <= Struct
        struct_wrapper = Anyolite::StructWrapper({{crystal_class}}).new({{new_obj}})
        new_obj_ptr = Pointer(Anyolite::StructWrapper({{crystal_class}})).malloc(size: 1, value: struct_wrapper)
        Anyolite::RbRefTable.add(Anyolite::RbRefTable.get_object_id(new_obj_ptr.value), new_obj_ptr.as(Void*))

        puts "> S: {{crystal_class}}: #{new_obj_ptr.value.inspect}" if Anyolite::RbRefTable.option_active?(:logging)

        destructor = Anyolite::RbTypeCache.destructor_method({{crystal_class}})
        Anyolite::RbCore.set_data_ptr_and_type({{obj}}, new_obj_ptr, Anyolite::RbTypeCache.register({{crystal_class}}, destructor))
      else
        new_obj_ptr = Pointer({{crystal_class}}).malloc(size: 1, value: {{new_obj}})
        Anyolite::RbRefTable.add(Anyolite::RbRefTable.get_object_id(new_obj_ptr.value), new_obj_ptr.as(Void*))

        puts "> C: {{crystal_class}}: #{new_obj_ptr.value.inspect}" if Anyolite::RbRefTable.option_active?(:logging)

        destructor = Anyolite::RbTypeCache.destructor_method({{crystal_class}})
        Anyolite::RbCore.set_data_ptr_and_type({{obj}}, new_obj_ptr, Anyolite::RbTypeCache.register({{crystal_class}}, destructor))
      end
    end
  end
end