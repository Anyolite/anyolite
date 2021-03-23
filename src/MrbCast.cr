# Module for specific casts of Crystal values into mruby values
module MrbCast
  # Explicit return methods

  def self.return_nil
    return MrbInternal.get_nil_value
  end

  def self.return_true
    return MrbInternal.get_true_value
  end

  def self.return_false
    return MrbInternal.get_false_value
  end

  def self.return_fixnum(value)
    return MrbInternal.get_fixnum_value(value)
  end

  def self.return_bool(value)
    return MrbInternal.get_bool_value(value ? 1 : 0)
  end

  def self.return_float(mrb, value)
    return MrbInternal.get_float_value(mrb, value)
  end

  def self.return_string(mrb, value)
    return MrbInternal.get_string_value(mrb, value)
  end

  # Implicit return methods

  def self.return_value(mrb : MrbInternal::MrbState*, value : Nil)
    self.return_nil
  end

  def self.return_value(mrb : MrbInternal::MrbState*, value : Bool)
    value ? self.return_true : return_false
  end

  def self.return_value(mrb : MrbInternal::MrbState*, value : Int)
    self.return_fixnum(value)
  end

  def self.return_value(mrb : MrbInternal::MrbState*, value : Float)
    self.return_float(mrb, value)
  end

  def self.return_value(mrb : MrbInternal::MrbState*, value : String)
    self.return_string(mrb, value)
  end

  def self.return_value(mrb : MrbInternal::MrbState*, value : Struct)
    ruby_class = MrbClassCache.get(typeof(value))

    destructor = MrbTypeCache.destructor_method(typeof(value))

    ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

    new_ruby_object = MrbInternal.new_empty_object(mrb, ruby_class, ptr.as(Void*), MrbTypeCache.register(typeof(value), destructor))

    struct_wrapper = MrbMacro.convert_from_ruby_struct(mrb, new_ruby_object, typeof(value))
    struct_wrapper.value = MrbWrap::StructWrapper(typeof(value)).new(value)

    MrbRefTable.add(MrbRefTable.get_object_id(struct_wrapper.value), ptr.as(Void*))

    return new_ruby_object
  end

  def self.return_value(mrb : MrbInternal::MrbState*, value : Object)
    ruby_class = MrbClassCache.get(typeof(value))

    destructor = MrbTypeCache.destructor_method(typeof(value))

    ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

    new_ruby_object = MrbInternal.new_empty_object(mrb, ruby_class, ptr.as(Void*), MrbTypeCache.register(typeof(value), destructor))

    MrbMacro.convert_from_ruby_object(mrb, new_ruby_object, typeof(value)).value = value

    MrbRefTable.add(MrbRefTable.get_object_id(value), ptr.as(Void*))

    return new_ruby_object
  end

  # Class check methods

  def self.check_for_undef(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_UNDEF
  end

  def self.check_for_nil(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_FALSE && value.value.value_int == 0
  end

  def self.check_for_true(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_TRUE
  end

  def self.check_for_false(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_FALSE && value.value.value_int != 0
  end

  def self.check_for_bool(value : MrbInternal::MrbValue)
    MrbCast.check_for_true(value) || MrbCast.check_for_false(value)
  end

  def self.check_for_fixnum(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_FIXNUM
  end

  def self.check_for_float(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_FLOAT
  end

  def self.check_for_string(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_STRING
  end

  def self.check_for_data(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_DATA
  end

  def self.cast_to_nil(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if MrbCast.check_for_nil(value)
      nil
    else
      MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to Nil.")
      nil
    end
  end

  def self.cast_to_bool(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if MrbCast.check_for_true(value)
      true
    elsif MrbCast.check_for_false(value)
      false
    else
      MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to Bool.")
      false
    end
  end

  def self.cast_to_int(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if MrbCast.check_for_fixnum(value)
      value.value.value_int
    else
      MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to Int.")
      0
    end
  end

  def self.cast_to_float(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if MrbCast.check_for_float(value)
      value.value.value_float
    else
      MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to Float.")
      0.0
    end
  end

  def self.cast_to_string(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if MrbCast.check_for_string(value)
      String.new(MrbInternal.mrb_str_to_cstr(mrb, value))
    else
      MrbInternal.mrb_raise_argument_error(mrb, "Could not cast #{value} to String.")
      ""
    end
  end

  macro check_custom_type(mrb, value, crystal_type)
    MrbInternal.mrb_obj_is_kind_of({{mrb}}, {{value}}, MrbClassCache.get({{crystal_type}})) != 0
  end

  def self.is_undef?(value : MrbInternal::MrbValue) # Just a more readable synonym
    MrbCast.check_for_undef(value)
  end

  # TODO: Object casting for this method
  # TODO: Is the method really required?

  def self.interpret_ruby_value(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    case value.tt
    when MrbInternal::MrbVType::MRB_TT_UNDEF  then MrbWrap::Undef
    when MrbInternal::MrbVType::MRB_TT_TRUE   then true
    when MrbInternal::MrbVType::MRB_TT_FALSE  then (value.value.value_int != 0 ? false : nil) # TODO: Use proper mruby methods
    when MrbInternal::MrbVType::MRB_TT_FIXNUM then MrbCast.cast_to_int(mrb, value)
    when MrbInternal::MrbVType::MRB_TT_FLOAT  then MrbCast.cast_to_float(mrb, value)
    when MrbInternal::MrbVType::MRB_TT_STRING then MrbCast.cast_to_string(mrb, value)
    else                                           MrbInternal.mrb_raise_argument_error(mrb, "MrbValue #{value} with #{value.tt} is not supported")
    end
  end

  # TODO: Conversions of other objects like arrays and hashes
end
