# This is a very simple approach to generate artificial references to the wrapped objects.
# Therefore, the GC won't delete the wrapped objects until necessary.
# Note that this is currently one-directional, so mruby might still delete Crystal objects generated from Crystal itself.
# Furthermore, this is only possible as a module due to C closure limitations.
# 
# TODO: Add compilation option for ignoring entry checks
module MrbRefTable
  @@content = {} of UInt64 => Tuple(Void*, Int64)
  @@logging = false
  @@warnings = true

  def self.get(identification)
    return @@content[identification][0]
  end

  def self.add(identification, value)
    puts "> Added reference #{identification} -> #{value}" if @@logging
    if @@content[identification]?
      if value != @@content[identification][0]
        puts "WARNING: Value #{identification} replaced pointers." if @@warnings
      end
      @@content[identification] = {value, @@content[identification][1] + 1}
    end
    @@content[identification] = {value, 1i64}
  end

  def self.delete(identification)
    puts "> Removed reference #{identification}" if @@logging
    if @@content[identification]?
      @@content[identification] = {@@content[identification][0], @@content[identification][1] - 1}
      if @@content[identification][1] <= 0
        @@content.delete(identification)
      end
    else
      puts "WARNING: Tried to remove unregistered object #{identification} from reference table." if @@warnings
    end
    nil
  end

  def self.is_registered?(identification)
    return @@content[identification]?
  end

  def self.inspect
    @@content.inspect
  end

  def self.logging
    @@logging
  end

  def self.warnings
    @@warnings
  end

  def self.logging=(value)
    @@logging = value
  end

  def self.warnings=(value)
    @@warnings = value
  end

  def self.reset
    @@content.clear
  end

  def self.get_object_id(value)
    if value.responds_to?(:mruby_ref_id)
      value.mruby_ref_id.to_u64
    elsif value.responds_to?(:object_id)
      value.object_id.to_u64
    else
      value.hash.to_u64
    end
  end
end
