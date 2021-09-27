module Anyolite
  # Reference to a mruby class
  class RbClass
    @class_ptr : RbCore::RClassPtr

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

    def initialize(@rb : RbInterpreter, @class_ptr : RbCore::RClassPtr, @under : RbModule | RbClass | Nil = nil)
      @name = String.new(RbCore.rb_class_name(@rb, @class_ptr))
    end

    def self.get_from_ruby_name(rb : RbInterpreter, name : String, under : RbModule | RbClass | Nil = nil)
      if under
        available = (RbCore.rb_class_defined_under(rb, under, name) != 0)
      else
        available = (RbCore.rb_class_defined(rb, name) != 0)
      end

      return nil if !available

      if under
        ruby_class = RbCore.rb_class_get_under(rb, under, name)
      else
        ruby_class = RbCore.rb_class_get(rb, name)
      end

      self.new(rb, ruby_class, under) if ruby_class
    end

    def to_unsafe
      return @class_ptr
    end
  end
end
