struct Proc
  def arg_types
    return T
  end

  def return_value
    return R
  end
end

module FormatString
  def self.format_char(type)
    char = 'o'

    if type == Bool
      char = 'b'
    elsif type <= Int
      char = 'i'
    elsif type <= Float
      char = 'f'
    elsif type <= String
      char = 'z'
    end

    return char
  end

  def self.get(proc)
    proc.arg_types.types.join { |type| self.format_char(type) }
  end
end
