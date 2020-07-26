module MrbCast

    def self.return_nil
        return MRubyInternal.get_nil_value
    end

    def self.return_true
        return MRubyInternal.get_true_value
    end

    def self.return_false
        return MRubyInternal.get_false_value
    end

    def self.return_fixnum(value)
        return MRubyInternal.get_fixnum_value(value)
    end

    def self.return_bool(value)
        return MRubyInternal.get_bool_value(value ? 1 : 0)
    end

    def self.return_float(mrb, value)
        return MRubyInternal.get_float_value(mrb, value)
    end

end