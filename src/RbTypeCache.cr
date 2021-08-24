module Anyolite
  # Cache for mruby data types, holding the destructor methods
  module RbTypeCache
    @@cache = {} of String => RbCore::RbDataType*

    def self.register(crystal_class : Class, destructor : RbCore::RbDataFunc)
      unless @@cache[crystal_class.name]?
        new_type = RbCore::RbDataType.new(struct_name: crystal_class.name, dfree: destructor)
        @@cache[crystal_class.name] = Pointer(RbCore::RbDataType).malloc(size: 1, value: new_type)
      end
      return @@cache[crystal_class.name]
    end

    def self.register_custom_destructor(crystal_class : Class, destructor : RbCore::RbDataFunc)
      new_type = RbCore::RbDataType.new(struct_name: crystal_class.name, dfree: destructor)
      Pointer(RbCore::RbDataType).malloc(size: 1, value: new_type)
    end

    macro destructor_method(crystal_class)
      Anyolite::Macro.new_rb_data_func do
        if {{crystal_class}} <= Struct || {{crystal_class}} <= Enum
          crystal_ptr = __ptr.as(Anyolite::StructWrapper({{crystal_class}})*)
          obj_id = Anyolite::RbRefTable.get_object_id(crystal_ptr.value)

          # Call optional mruby callback
          if (crystal_value = crystal_ptr.value.content).responds_to?(:rb_finalize)
            if Anyolite::RbRefTable.may_delete?(obj_id)
              crystal_value.rb_finalize(__rb)
            end
          end
        else
          crystal_ptr = __ptr.as({{crystal_class}}*)
          obj_id = Anyolite::RbRefTable.get_object_id(crystal_ptr.value)

          if (crystal_value = crystal_ptr.value).responds_to?(:rb_finalize)
            if Anyolite::RbRefTable.may_delete?(obj_id)
              crystal_value.rb_finalize(__rb)
            end
          end
        end

        # Delete the Crystal reference to this object
        Anyolite::RbRefTable.delete(obj_id)
      end
    end
  end
end
