# Cache for mruby data types, holding the destructor methods
module MrbTypeCache
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
      crystal_ptr = ptr.as({{crystal_class}}*)

      # Call optional mruby callback
      if (crystal_value = crystal_ptr.value).responds_to?(:mrb_finalize)
        crystal_value.mrb_finalize(mrb)
      end

      # Delete the Crystal reference to this object
      MrbRefTable.delete(crystal_ptr.value.object_id)
    }
  end
end
