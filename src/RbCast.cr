module Anyolite
  # Module for specific casts of Crystal values into mruby values
  module RbCast
    # Explicit return methods

    def self.return_nil
      return RbCore.get_nil_value
    end

    def self.return_true
      return RbCore.get_true_value
    end

    def self.return_false
      return RbCore.get_false_value
    end

    def self.return_fixnum(value)
      return RbCore.get_fixnum_value(value)
    end

    def self.return_bool(value)
      return RbCore.get_bool_value(value ? 1 : 0)
    end

    def self.return_float(rb, value)
      return RbCore.get_float_value(rb, value)
    end

    def self.return_string(rb, value)
      return RbCore.get_string_value(rb, value)
    end

    def self.return_array(rb, value)
      array_size = value.size

      array_values = Pointer(RbCore::RbValue).malloc(size: array_size) do |i|
        self.return_value(rb, value[i])
      end

      return RbCore.rb_ary_new_from_values(rb, array_size, array_values)
    end

    def self.return_symbol(rb, value)
      return RbCore.get_symbol_value_of_string(rb, value.to_s)
    end

    def self.return_hash(rb, value)
      hash_size = value.size

      rb_hash = RbCore.rb_hash_new(rb)

      value.each do |index, element|
        rb_element = self.return_value(rb, element)
        rb_key = self.return_value(rb, index)

        RbCore.rb_hash_set(rb, rb_hash, rb_key, rb_element)
      end

      return rb_hash
    end

    # Implicit return methods

    def self.return_value(rb : RbCore::State*, value : Nil)
      self.return_nil
    end

    def self.return_value(rb : RbCore::State*, value : Bool)
      value ? self.return_true : return_false
    end

    def self.return_value(rb : RbCore::State*, value : Int)
      self.return_fixnum(value)
    end

    def self.return_value(rb : RbCore::State*, value : Float)
      self.return_float(rb, value)
    end

    def self.return_value(rb : RbCore::State*, value : String)
      self.return_string(rb, value)
    end

    def self.return_value(rb : RbCore::State*, value : Symbol)
      self.return_symbol(rb, value)
    end

    def self.return_value(rb : RbCore::State*, value : Array)
      self.return_array(rb, value)
    end

    def self.return_value(rb : RbCore::State*, value : Hash)
      self.return_hash(rb, value)
    end

    def self.return_value(rb : RbCore::State*, value : Struct | Enum)
      ruby_class = RbClassCache.get(typeof(value))

      destructor = RbTypeCache.destructor_method(typeof(value))

      ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

      new_ruby_object = RbCore.new_empty_object(rb, ruby_class, ptr.as(Void*), RbTypeCache.register(typeof(value), destructor))

      struct_wrapper = Macro.convert_from_ruby_struct(rb, new_ruby_object, typeof(value))
      struct_wrapper.value = StructWrapper(typeof(value)).new(value)

      RbRefTable.add(RbRefTable.get_object_id(struct_wrapper.value), ptr.as(Void*))

      return new_ruby_object
    end

    def self.return_value(rb : RbCore::State*, value : Object)
      ruby_class = RbClassCache.get(typeof(value))

      destructor = RbTypeCache.destructor_method(typeof(value))

      ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

      new_ruby_object = RbCore.new_empty_object(rb, ruby_class, ptr.as(Void*), RbTypeCache.register(typeof(value), destructor))

      Macro.convert_from_ruby_object(rb, new_ruby_object, typeof(value)).value = value

      RbRefTable.add(RbRefTable.get_object_id(value), ptr.as(Void*))

      return new_ruby_object
    end

    # Weak reference passing methods
    # NOTE: These are highly untested and might still be unstable or might even leak memory

    def self.pass_value(rb : RbCore::State*, value : Nil | Bool | Int | Float | String)
      self.return_value(rb, value)
    end

    def self.pass_value(rb : RbCore::State*, value : Struct | Enum)
      ruby_class = RbClassCache.get(typeof(value))

      destructor = ->(rb_state : Anyolite::RbCore::State*, ptr : Void*) {}

      ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

      new_ruby_object = RbCore.new_empty_object(rb, ruby_class, ptr.as(Void*), RbTypeCache.register_custom_destructor(typeof(value), destructor))

      struct_wrapper = Macro.convert_from_ruby_struct(rb, new_ruby_object, typeof(value))
      struct_wrapper.value = StructWrapper(typeof(value)).new(value)
      
      return new_ruby_object
    end

    def self.pass_value(rb : RbCore::State*, value : Object)
      ruby_class = RbClassCache.get(typeof(value))

      destructor = ->(rb_state : Anyolite::RbCore::State*, ptr : Void*) {}

      ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

      new_ruby_object = RbCore.new_empty_object(rb, ruby_class, ptr.as(Void*), RbTypeCache.register_custom_destructor(typeof(value), destructor))

      Macro.convert_from_ruby_object(rb, new_ruby_object, typeof(value)).value = value

      return new_ruby_object
    end

    # Class check methods

    def self.check_for_undef(value : RbCore::RbValue)
      RbCore.check_rb_undef(value) != 0
    end

    def self.check_for_nil(value : RbCore::RbValue)
      RbCore.check_rb_nil(value) != 0
    end

    def self.check_for_true(value : RbCore::RbValue)
      RbCore.check_rb_true(value) != 0
    end

    def self.check_for_false(value : RbCore::RbValue)
      RbCore.check_rb_false(value) != 0
    end

    def self.check_for_bool(value : RbCore::RbValue)
      RbCast.check_for_true(value) || RbCast.check_for_false(value)
    end

    def self.check_for_fixnum(value : RbCore::RbValue)
      RbCore.check_rb_fixnum(value) != 0
    end

    def self.check_for_float(value : RbCore::RbValue)
      RbCore.check_rb_float(value) != 0
    end

    def self.check_for_string(value : RbCore::RbValue)
      RbCore.check_rb_string(value) != 0
    end

    def self.check_for_array(value : RbCore::RbValue)
      RbCore.check_rb_array(value) != 0
    end

    def self.check_for_hash(value : RbCore::RbValue)
      RbCore.check_rb_hash(value) != 0
    end

    def self.check_for_data(value : RbCore::RbValue)
      RbCore.check_rb_data(value) != 0
    end

    # TODO: Put ruby class name into string instead of internal value... value

    def self.cast_to_nil(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_nil(value)
        nil
      else
        RbCore.rb_raise_argument_error(rb, "Could not cast #{value} to Nil.")
        nil
      end
    end

    def self.cast_to_bool(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_true(value)
        true
      elsif RbCast.check_for_false(value)
        false
      else
        RbCore.rb_raise_argument_error(rb, "Could not cast #{value} to Bool.")
        false
      end
    end

    def self.cast_to_int(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_fixnum(value)
        RbCore.get_rb_fixnum(value)
      else
        RbCore.rb_raise_argument_error(rb, "Could not cast #{value} to Int.")
        0
      end
    end

    def self.cast_to_float(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_float(value)
        RbCore.get_rb_float(value)
      else
        RbCore.rb_raise_argument_error(rb, "Could not cast #{value} to Float.")
        0.0
      end
    end

    def self.cast_to_string(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_string(value)
        String.new(RbCore.get_rb_string(rb, value))
      else
        RbCore.rb_raise_argument_error(rb, "Could not cast #{value} to String.")
        ""
      end
    end

    macro check_custom_type(rb, value, crystal_type)
      Anyolite::RbCore.rb_obj_is_kind_of({{rb}}, {{value}}, Anyolite::RbClassCache.get({{crystal_type}})) != 0
    end

    def self.is_undef?(value) # Excludes non-RbValue types as well
      if value.is_a?(RbCore::RbValue)
        Anyolite::RbCast.check_for_undef(value)
      else
        false
      end
    end

    # TODO: Conversions of other objects like arrays and hashes
  end
end
