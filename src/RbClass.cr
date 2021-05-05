module Anyolite
  # Reference to a mruby class
  class RbClass
    @class_ptr : RbCore::RClass*

    def initialize(@rb : RbInterpreter, @name : String, superclass : RbModule | RbClass | Nil = nil, @under : RbModule | RbClass | Nil = nil)
      if superclass.is_a?(RbModule)
        raise "Super class #{superclass} of #{@name} is a RbModule."
      end

      actual_superclass = superclass ? superclass.to_unsafe : RbCore.get_object_class(@rb)

      if mod = @under
        @class_ptr = RbCore.rb_define_class_under(@rb, mod, @name, actual_superclass)
      else
        @class_ptr = RbCore.rb_define_class(@rb, @name, actual_superclass)
      end
    end

    def to_unsafe
      return @class_ptr
    end
  end
end
