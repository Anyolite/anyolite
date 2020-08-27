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

    # TODO: Allow non-defaultable constructors
    new_ruby_object = MrbInternal.new_empty_object(mrb, ruby_class)
    MrbMacro.convert_from_ruby_object(mrb, new_ruby_object, typeof(value)).value = value

    MrbRefTable.add(value.object_id, pointerof(value).as(Void*))

    return new_ruby_object
  end

  # TODO: Conversions of other objects
end
