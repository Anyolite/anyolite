module Anyolite
  module Macro
    macro convert_from_ruby_object(rb, obj, crystal_type)
      if !Anyolite::RbCore.get_data_ptr({{obj}})
        %obj_class = Anyolite::RbCore.get_class_of_obj({{rb}}, {{obj}})

        %rb_class_name = String.new(Anyolite::RbCore.rb_class_name({{rb}}, %obj_class))
        Anyolite.raise_runtime_error "Object of class #{%rb_class_name} has content incompatible to Crystal class #{{{crystal_type.stringify}}}."
      end

      if !Anyolite::RbCast.check_custom_type({{rb}}, {{obj}}, {{crystal_type}})
        %obj_class = Anyolite::RbCore.get_class_of_obj({{rb}}, {{obj}})

        %rb_class_name = String.new(Anyolite::RbCore.rb_class_name({{rb}}, %obj_class))
        Anyolite.raise_argument_error("Invalid data type #{%rb_class_name} for object class #{{{crystal_type.stringify}}}.")
      end

      %ptr = Anyolite::RbCore.get_data_ptr({{obj}})
      %ptr.as({{crystal_type}}*)
    end

    macro convert_from_ruby_struct(rb, obj, crystal_type)
      if !Anyolite::RbCore.get_data_ptr({{obj}})
        %obj_class = Anyolite::RbCore.get_class_of_obj({{rb}}, {{obj}})

        %rb_class_name = String.new(Anyolite::RbCore.rb_class_name({{rb}}, %obj_class))
        Anyolite.raise_runtime_error "Object of class #{%rb_class_name} has content incompatible to Crystal struct #{{{crystal_type.stringify}}}."
      end

      if !Anyolite::RbCast.check_custom_type({{rb}}, {{obj}}, {{crystal_type}})
        %obj_class = Anyolite::RbCore.get_class_of_obj({{rb}}, {{obj}})

        %rb_class_name = String.new(Anyolite::RbCore.rb_class_name({{rb}}, %obj_class))
        Anyolite.raise_argument_error("Invalid data type #{%rb_class_name} for struct class #{{{crystal_type.stringify}}}")
      end
      
      %ptr = Anyolite::RbCore.get_data_ptr({{obj}})
      %ptr.as(Anyolite::StructWrapper({{crystal_type}})*)
    end
  end
end
