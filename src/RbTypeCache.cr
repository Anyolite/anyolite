module Anyolite
  # Cache for mruby data types, holding the destructor methods
  module RbTypeCache
    @@cache = {} of String => MrbInternal::MrbDataType*

    def self.register(crystal_class : Class, destructor : Proc(MrbInternal::MrbState*, Void*, Void))
      unless @@cache[crystal_class.name]?
        new_type = MrbInternal::MrbDataType.new(struct_name: crystal_class.name, dfree: destructor)
        @@cache[crystal_class.name] = Pointer(MrbInternal::MrbDataType).malloc(size: 1, value: new_type)
      end
      return @@cache[crystal_class.name]
    end

    macro destructor_method(crystal_class)
      ->(mrb : MrbInternal::MrbState*, ptr : Void*) {
        if {{crystal_class}} <= Struct
          crystal_ptr = ptr.as(Anyolite::StructWrapper({{crystal_class}})*)

          # Call optional mruby callback
          if (crystal_value = crystal_ptr.value.content).responds_to?(:mrb_finalize)
            crystal_value.mrb_finalize(mrb)
          end
        else
          crystal_ptr = ptr.as({{crystal_class}}*)

          if (crystal_value = crystal_ptr.value).responds_to?(:mrb_finalize)
            crystal_value.mrb_finalize(mrb)
          end
        end

        # Delete the Crystal reference to this object
        Anyolite::RbRefTable.delete(Anyolite::RbRefTable.get_object_id(crystal_ptr.value))
      }
    end
  end
end
