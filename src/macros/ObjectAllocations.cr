module Anyolite
  module Macro
    macro allocate_constructed_object(rb, crystal_class, obj, new_obj)
      # Call initializer method if available
      if {{new_obj}}.responds_to?(:rb_initialize)
        {{new_obj}}.rb_initialize({{rb}})
      end

      # Allocate memory so we do not lose this object
      if {{crystal_class}} <= Struct || {{crystal_class}} <= Enum
        %struct_wrapper = Anyolite::StructWrapper({{crystal_class}}).new({{new_obj}})
        %new_obj_ptr = Pointer(Anyolite::StructWrapper({{crystal_class}})).malloc(size: 1, value: %struct_wrapper)
        Anyolite::RbRefTable.add(Anyolite::RbRefTable.get_object_id(%new_obj_ptr.value), %new_obj_ptr.as(Void*), {{obj}})

        puts "> S: {{crystal_class}}: #{%new_obj_ptr.value.inspect}" if Anyolite::RbRefTable.option_active?(:logging)

        %destructor = Anyolite::RbTypeCache.destructor_method({{crystal_class}})
        Anyolite::RbCore.set_data_ptr_and_type({{obj}}, %new_obj_ptr, Anyolite::RbTypeCache.register({{crystal_class}}, %destructor))
      else
        %new_obj_ptr = Pointer({{crystal_class}}).malloc(size: 1, value: {{new_obj}})
        Anyolite::RbRefTable.add(Anyolite::RbRefTable.get_object_id(%new_obj_ptr.value), %new_obj_ptr.as(Void*), {{obj}})

        puts "> C: {{crystal_class}}: #{%new_obj_ptr.value.inspect}" if Anyolite::RbRefTable.option_active?(:logging)

        %destructor = Anyolite::RbTypeCache.destructor_method({{crystal_class}})
        Anyolite::RbCore.set_data_ptr_and_type({{obj}}, %new_obj_ptr, Anyolite::RbTypeCache.register({{crystal_class}}, %destructor))
      end
    end

    macro create_new_allocated_object(rb, crystal_class, ruby_class_value, new_obj)
      # Allocate memory so we do not lose this object
      if {{crystal_class}} <= Struct || {{crystal_class}} <= Enum
        %struct_wrapper = Anyolite::StructWrapper({{crystal_class}}).new({{new_obj}})
        %new_obj_ptr = Pointer(Anyolite::StructWrapper({{crystal_class}})).malloc(size: 1, value: %struct_wrapper)
        %destructor = Anyolite::RbTypeCache.destructor_method({{crystal_class}})

        %created_new_rb_obj = Anyolite::RbCore.new_empty_object({{rb}}, {{ruby_class_value}}, %new_obj_ptr.as(Void*), Anyolite::RbTypeCache.register({{crystal_class}}, %destructor))

        if {{new_obj}}.responds_to?(:rb_initialize)
          {{new_obj}}.rb_initialize({{rb}})
        end

        Anyolite::RbRefTable.add(Anyolite::RbRefTable.get_object_id(%new_obj_ptr.value), %new_obj_ptr.as(Void*), %created_new_rb_obj)

        puts "> S: {{crystal_class}}: #{%new_obj_ptr.value.inspect}" if Anyolite::RbRefTable.option_active?(:logging)

        %created_new_rb_obj
      else
        %new_obj_ptr = Pointer({{crystal_class}}).malloc(size: 1, value: {{new_obj}})
        %destructor = Anyolite::RbTypeCache.destructor_method({{crystal_class}})

        %created_new_rb_obj = Anyolite::RbCore.new_empty_object({{rb}}, {{ruby_class_value}}, %new_obj_ptr.as(Void*), Anyolite::RbTypeCache.register({{crystal_class}}, %destructor))

        if {{new_obj}}.responds_to?(:rb_initialize)
          {{new_obj}}.rb_initialize({{rb}})
        end

        Anyolite::RbRefTable.add(Anyolite::RbRefTable.get_object_id(%new_obj_ptr.value), %new_obj_ptr.as(Void*), %created_new_rb_obj)

        puts "> C: {{crystal_class}}: #{%new_obj_ptr.value.inspect}" if Anyolite::RbRefTable.option_active?(:logging)

        %created_new_rb_obj
      end
    end
  end
end
