module Anyolite
  module Macro
    macro convert_from_ruby_object(rb, obj, crystal_type)
      if !Anyolite::RbCast.check_custom_type({{rb}}, {{obj}}, {{crystal_type}})
        obj_class = Anyolite::RbCore.get_class_of_obj({{rb}}, {{obj}})
        Anyolite::RbCore.rb_raise_argument_error({{rb}}, "Invalid data type #{obj_class} for object #{{{obj}}}:\n Should be #{{{crystal_type}}} -> Anyolite::RbClassCache.get({{crystal_type}}) instead.")
      end

      ptr = Anyolite::RbCore.get_data_ptr({{obj}})
      ptr.as({{crystal_type}}*)
    end

    macro convert_from_ruby_struct(rb, obj, crystal_type)
      if !Anyolite::RbCast.check_custom_type({{rb}}, {{obj}}, {{crystal_type}})
        obj_class = Anyolite::RbCore.get_class_of_obj({{rb}}, {{obj}})
        Anyolite::RbCore.rb_raise_argument_error({{rb}}, "Invalid data type #{obj_class} for object #{{{obj}}}:\n Should be #{{{crystal_type}}} -> Anyolite::RbClassCache.get({{crystal_type}}) instead.")
      end
      
      ptr = Anyolite::RbCore.get_data_ptr({{obj}})
      ptr.as(Anyolite::StructWrapper({{crystal_type}})*)
    end
  end
end