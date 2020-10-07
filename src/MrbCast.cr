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

  def self.return_value(mrb : MrbInternal::MrbState*, value : Object)
    ruby_class = MrbClassCache.get(typeof(value))

    destructor = MrbTypeCache.destructor_method(typeof(value))

    ptr = Pointer(typeof(value)).malloc(size: 1, value: value)

    new_ruby_object = MrbInternal.new_empty_object(mrb, ruby_class, ptr.as(Void*), MrbTypeCache.register(typeof(value), destructor))
    MrbMacro.convert_from_ruby_object(mrb, new_ruby_object, typeof(value)).value = value

    MrbRefTable.add(MrbRefTable.get_object_id(value), ptr.as(Void*))

    puts "> #{value.class}: #{value}" if MrbRefTable.option_active?(:logging)

    return new_ruby_object
  end

  # TODO: Use proper casting methods from mruby

  def self.cast_to_bool(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if value.tt == MrbInternal::MrbVType::MRB_TT_TRUE
      true
    elsif value.tt == MrbInternal::MrbVType::MRB_TT_FALSE && value.value.value_int != 0
      false
    else
      raise("ERROR: Wrong arg") # TODO: Proper mruby message
    end
  end

  def self.cast_to_int(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if value.tt == MrbInternal::MrbVType::MRB_TT_FIXNUM
      value.value.value_int
    else
      raise("ERROR: Wrong arg") # TODO: Proper mruby message
    end
  end

  def self.cast_to_float(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if value.tt == MrbInternal::MrbVType::MRB_TT_FLOAT
      value.value.value_float
    else
      raise("ERROR: Wrong arg") # TODO: Proper mruby message
    end
  end

  def self.cast_to_string(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    if value.tt == MrbInternal::MrbVType::MRB_TT_STRING
      String.new(MrbInternal.mrb_str_to_cstr(mrb, value))
    else
      raise("ERROR: Wrong arg") # TODO: Proper mruby message
    end
  end

  def self.is_undef?(value : MrbInternal::MrbValue)
    value.tt == MrbInternal::MrbVType::MRB_TT_UNDEF
  end

  # TODO: Object casting for this method

  def self.interpret_ruby_value(mrb : MrbInternal::MrbState*, value : MrbInternal::MrbValue)
    case value.tt
      when MrbInternal::MrbVType::MRB_TT_UNDEF then MrbWrap::Undef
      when MrbInternal::MrbVType::MRB_TT_TRUE then true
      when MrbInternal::MrbVType::MRB_TT_FALSE then (value.value.value_int != 0 ? false : nil)  # TODO: Use proper mruby methods
      when MrbInternal::MrbVType::MRB_TT_FIXNUM then MrbCast.cast_to_int(mrb, value)
      when MrbInternal::MrbVType::MRB_TT_FLOAT then MrbCast.cast_to_float(mrb, value)
      when MrbInternal::MrbVType::MRB_TT_STRING then MrbCast.cast_to_string(mrb, value)
      else raise("MrbValue #{value} with #{value.tt} is not supported")
    end
  end

  # TODO: Conversions of other objects like arrays and hashes
end
