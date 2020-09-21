# This is a very simple approach to generate artificial references to the wrapped objects.
# Therefore, the GC won't delete the wrapped objects until necessary.
# Note that this is currently one-directional, so Mruby might still delete Crystal objects generated from Crystal itself.
# 
# TODO: Add reset method or transform this module into a class
# TODO: Add compilation option for ignoring entry checks
module MrbRefTable
  @@content = {} of UInt64 => Tuple(Void*, UInt64)

  def self.get(identification)
    return @@content[identification][0]
  end

  def self.add(identification, value)
    puts "* Added ref #{identification} -> #{value}"
    if @@content[identification]?
      if value != @@content[identification][0]
        puts "WARNING: Value #{identification} replaced pointers."
      end
      @@content[identification] = {value, @@content[identification][1] + 1}
    end
    @@content[identification] = {value, 1u64}
  end

  def self.delete(identification)
    if @@content[identification]?
      puts "* Deleted ref #{identification} -> #{@@content[identification]}"
      @@content[identification] = {@@content[identification][0], @@content[identification][1] - 1}
      if @@content[identification][1] <= 0
        @@content.delete(identification)
      end
    else
      puts "WARNING: Tried to remove unregistered object #{identification} from reference table."
    end
    nil
  end

  def self.is_registered?(identification)
    return @@content[identification]?
  end

  def self.inspect
    @@content.inspect
  end

  def self.reset
    @@content.clear
  end
end
