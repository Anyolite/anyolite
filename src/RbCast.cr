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

    def self.return_float(rb : RbCore::State*, value)
      return RbCore.get_float_value(rb, value)
    end

    def self.return_string(rb : RbCore::State*, value)
      return RbCore.get_string_value(rb, value)
    end

    def self.return_array(rb : RbCore::State*, value)
      array_size = value.size

      array_values = Pointer(RbCore::RbValue).malloc(size: array_size) do |i|
        RbCast.return_value(rb, value[i])
      end

      return RbCore.rb_ary_new_from_values(rb, array_size, array_values)
    end

    def self.return_symbol(rb : RbCore::State*, value)
      return RbCore.get_symbol_value_of_string(rb, value.to_s)
    end

    def self.return_regex(rb : RbCore::State*, value)
      Anyolite::Macro.convert_regex_from_crystal_to_ruby(rb, value)
    end

    def self.return_hash(rb : RbCore::State*, value)
      hash_size = value.size

      rb_hash = RbCore.rb_hash_new(rb)

      value.each do |index, element|
        rb_element = RbCast.return_value(rb, element)
        rb_key = RbCast.return_value(rb, index)

        RbCore.rb_hash_set(rb, rb_hash, rb_key, rb_element)
      end

      return rb_hash
    end

    def self.return_struct_or_enum(rb : RbCore::State*, value : Struct | Enum)
      # NOTE: Equal structs do not have the same object IDs, so they are not cached
      ruby_class = RbClassCache.get(value.class)

      destructor = RbTypeCache.destructor_method(typeof(value))

      ptr = Pointer(Anyolite::StructWrapper(typeof(value))).malloc(size: 1, value: StructWrapper(typeof(value)).new(value))
      new_ruby_object = RbCore.new_empty_object(rb, ruby_class, ptr.as(Void*), RbTypeCache.register(value.class, destructor))

      RbRefTable.add(RbRefTable.get_object_id(ptr.value), ptr.as(Void*), new_ruby_object)

      return new_ruby_object
    end

    def self.return_object(rb : RbCore::State*, value : Object)
      ruby_class = RbClassCache.get(value.class)
      value_id = RbRefTable.get_object_id(value)

      if RbRefTable.is_registered?(value_id)
        return RbRefTable.get_rb_value(value_id)
      else
        destructor = RbTypeCache.destructor_method(typeof(value))

        ptr = Pointer(typeof(value)).malloc(size: 1, value: value)
        new_ruby_object = RbCore.new_empty_object(rb, ruby_class, ptr.as(Void*), RbTypeCache.register(value.class, destructor))

        RbRefTable.add(value_id, ptr.as(Void*), new_ruby_object)

        return new_ruby_object
      end
    end

    def self.return_value(rb : RbCore::State*, value : Object)
      if value.is_a?(Nil)
        RbCast.return_nil
      elsif value.is_a?(Bool)
        value ? RbCast.return_true : RbCast.return_false
      elsif value.is_a?(Int)
        RbCast.return_fixnum(value)
      elsif value.is_a?(Float)
        RbCast.return_float(rb, value)
      elsif value.is_a?(Char)
        RbCast.return_string(rb, value.to_s)
      elsif value.is_a?(String)
        RbCast.return_string(rb, value)
      elsif value.is_a?(Symbol)
        RbCast.return_symbol(rb, value)
      elsif value.is_a?(Regex)
        RbCast.return_regex(rb, value)
      elsif value.is_a?(Array)
        RbCast.return_array(rb, value)
      elsif value.is_a?(Hash)
        RbCast.return_hash(rb, value)
      elsif value.is_a?(Pointer)
        RbCast.return_object(rb, HelperClasses::AnyolitePointer.new(value))
      elsif value.is_a?(RbRef)
        value.to_unsafe
      elsif value.is_a?(Struct) || value.is_a?(Enum)
        RbCast.return_struct_or_enum(rb, value)
      else
        RbCast.return_object(rb, value)
      end
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

    def self.check_for_symbol(value : RbCore::RbValue)
      RbCore.check_rb_symbol(value) != 0
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

    def self.casting_error(rb : RbCore::State*, value, crystal_class, rescue_value)
      rb_inspect_string = RbCore.rb_inspect(rb, value)
      rb_class = RbCore.get_class_of_obj(rb, value)

      class_name = String.new(RbCore.rb_class_name(rb, rb_class))

      value_debug = RbCast.cast_to_string(rb, rb_inspect_string)
      Anyolite.raise_argument_error("Could not cast value #{value_debug} of class #{class_name} to #{crystal_class}.")
      rescue_value
    end

    def self.cast_to_nil(rb : RbCore::State*, value : RbCore::RbValue)
      # NOTE: If a nil class is expected, there is no point in rejecting objects
      # TODO: Maybe add an option for this
      if RbCast.check_for_nil(value) || true
        nil
      else
        RbCast.casting_error(rb, value, Nil, nil)
      end
    end

    def self.cast_to_bool(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_true(value)
        true
      elsif RbCast.check_for_false(value)
        false
      else
        RbCast.casting_error(rb, value, Bool, false)
      end
    end

    def self.cast_to_int(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_fixnum(value)
        RbCore.get_rb_fixnum(value)
      else
        RbCast.casting_error(rb, value, Int, 0)
      end
    end

    def self.cast_to_float(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_float(value)
        RbCore.get_rb_float(value)
      elsif RbCast.check_for_fixnum(value)
        RbCore.get_rb_fixnum(value).to_f
      else
        RbCast.casting_error(rb, value, Float, 0.0)
      end
    end

    def self.cast_to_char(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_string(value)
        str = String.new(RbCore.get_rb_string(rb, value))
        # TODO: Maybe also exclude longer strings to avoid confusion?
        if str.empty?
          RbCast.casting_error(rb, value, Char, '\0')
        else
          str[0]
        end
      else
        RbCast.casting_error(rb, value, Char, '\0')
      end
    end

    # TODO: Maybe add an option for implicit casts?
    def self.cast_to_string(rb : RbCore::State*, value : RbCore::RbValue)
      if RbCast.check_for_string(value)
        String.new(RbCore.get_rb_string(rb, value))
      elsif RbCast.check_for_symbol(value)
        String.new(RbCore.get_rb_string(rb, RbCore.rb_inspect(rb, value)))
      else
        RbCast.casting_error(rb, value, String, "")
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
