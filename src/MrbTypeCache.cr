class Object
  def finalize
    
  end
end

module MrbTypeCache
  @@cache = {} of String => MrbInternal::MrbDataType*

  def self.register(crystal_class : Class, destructor : Proc(MrbInternal::MrbState*, Void*, Void))
    new_type = MrbInternal::MrbDataType.new(struct_name: crystal_class.name, dfree: destructor)
    @@cache[crystal_class.name] = Pointer(MrbInternal::MrbDataType).malloc(size: 1, value: new_type)
    return @@cache[crystal_class.name]
  end

  macro destructor_method(crystal_class)
    ->(mrb : MrbInternal::MrbState*, ptr : Void*) {
      ptr.as({{crystal_class}}*).value.finalize
      GC.free(ptr)
    }
  end
end
