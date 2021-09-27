module Anyolite
  # Reference to a mruby module
  class RbModule
    @module_ptr : RbCore::RClassPtr

    def initialize(@rb : RbInterpreter, @name : String, @under : RbModule | RbClass | Nil = nil)
      if mod = @under
        @module_ptr = RbCore.rb_define_module_under(@rb, mod, @name)
      else
        @module_ptr = RbCore.rb_define_module(@rb, @name)
      end
    end

    def initialize(@rb : RbInterpreter, @module_ptr : RbCore::RClassPtr, @under : RbModule | RbClass | Nil = nil)
      @name = String.new(RbCore.rb_class_name(@rb, @module_ptr))
    end

    def self.get_from_ruby_name(rb : RbInterpreter, name : String, under : RbModule | RbClass | Nil = nil)
      if under
        available = (RbCore.rb_module_defined_under(rb, under, name) != 0)
      else
        available = (RbCore.rb_module_defined(rb, name) != 0)
      end

      return nil if !available
      
      if under
        ruby_module = RbCore.rb_module_get_under(rb, under, name)
      else
        ruby_module = RbCore.rb_module_get(rb, name)
      end

      # Does not work yet, why?

      self.new(rb, ruby_module, under) if ruby_module
    end

    def to_rb_obj
      RbCore.get_rb_obj_value(@class_ptr)
    end

    def to_unsafe
      return @module_ptr
    end
  end
end
