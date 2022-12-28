module Anyolite
  # Wrapper for an mruby state reference
  # NOTE: Do not create more than one at a time!
  class RbInterpreter
    @rb_ptr : RbCore::State*
    property depth : UInt32 = 0

    def self.create
      rb = self.new

      Anyolite::HelperClasses.load_all(rb)

      yield rb
      rb.close
    end

    def initialize
      @rb_ptr = 
      {% if flag?(:anyolite_external_ruby) %}
        Pointer(Anyolite::RbCore::State).null
      {% else %}
        RbCore.rb_open
      {% end %}
      RbRefTable.set_current_interpreter(self)
    end

    def close
      {% unless flag?(:anyolite_external_ruby) %}
        RbCore.rb_close(@rb_ptr)
      {% end %}
      RbRefTable.reset
      RbTypeCache.reset
      RbClassCache.reset
    end

    def to_unsafe
      return @rb_ptr
    end

    def execute_script_line(str : String, clear_error : Bool = true)
      @depth += 1
      value = RbCore.execute_script_line(@rb_ptr, str)
      @depth -= 1
      RbCore.clear_last_rb_error(@rb_ptr) if clear_error
      value
    end

    def load_script_from_file(filename : String)
      @depth += 1
      RbCore.load_script_from_file(@rb_ptr, filename)
      @depth -= 1
    end

    def execute_bytecode(bytecode : Array(UInt8))
      @depth += 1
      RbCore.execute_bytecode(@rb_ptr, bytecode)
      @depth -= 1
    end

    def load_bytecode_from_file(filename : String)
      @depth += 1
      RbCore.load_bytecode_from_file(@rb_ptr, filename)
      @depth -= 1
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
