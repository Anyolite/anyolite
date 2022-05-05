module Anyolite
  # Wrapper for an mruby state reference
  # NOTE: Do not create more than one at a time!
  class RbInterpreter
    @rb_ptr : RbCore::State*

    def self.create
      rb = self.new

      Anyolite::HelperClasses.load_all(rb)

      yield rb
      rb.close
    end

    def initialize
      @rb_ptr = RbCore.rb_open
      RbRefTable.set_current_interpreter(self)
    end

    def close
      RbCore.rb_close(@rb_ptr)
      RbRefTable.reset
      RbTypeCache.reset
      RbClassCache.reset
    end

    def to_unsafe
      return @rb_ptr
    end

    def execute_script_line(str : String)
      RbCore.execute_script_line(@rb_ptr, str)
    end

    def load_script_from_file(filename : String)
      RbCore.load_script_from_file(@rb_ptr, filename)
    end

    def execute_bytecode(bytecode : Array(UInt8))
      RbCore.execute_bytecode(@rb_ptr, bytecode)
    end

    def load_bytecode_from_file(filename : String)
      RbCore.load_bytecode_from_file(@rb_ptr, filename)
    end

    # TODO: Use internal mruby arg count in future versions
    def define_method(name : String, c : RbClass | RbModule, proc : RbCore::RbFunc)
      if c.is_a?(RbModule)
        raise "Tried to define method #{name} for RbModule #{c}"
      else
        RbCore.rb_define_method(@rb_ptr, c, name, proc, 1)
      end
    end

    def define_module_function(name : String, mod : RbModule | RbClass, proc : RbCore::RbFunc)
      if mod.is_a?(RbModule)
        RbCore.rb_define_module_function(@rb_ptr, mod, name, proc, 1)
      else
        RbCore.rb_define_class_method(@rb_ptr, mod, name, proc, 1)
      end
    end

    def define_class_method(name : String, c : RbClass | RbModule, proc : RbCore::RbFunc)
      if c.is_a?(RbModule)
        RbCore.rb_define_module_function(@rb_ptr, c, name, proc, 1)
      else
        RbCore.rb_define_class_method(@rb_ptr, c, name, proc, 1)
      end
    end
  end
end
