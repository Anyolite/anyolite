# This is a very simple approach to generate artificial references to the wrapped objects.
# Therefore, the GC won't delete the wrapped objects until necessary.
# Note that this is currently one-directional, so Mruby might still delete Crystal objects generated from Crystal itself.
# 
# TODO: Add reset method or transform this module into a class
# TODO: Add compilation option for ignoring entry checks
module MrbRefTable
  @@content = {} of UInt64 => Void*

  def self.get(identification)
    return @@content[identification]
  end

  def self.add(identification, value)
    if @@content[identification]?
      puts "WARNING: Tried to add object #{identification} to already existing reference table entry."
    end
    @@content[identification] = value
  end

  def self.delete(identification)
    if @@content[identification]?
      @@content.delete(identification)
    else
      puts "WARNING: Tried to remove unregistered object #{identification} from reference table."
    end
    nil
  end

  def self.is_registered?(identification)
    return @@content[identification]?
  end
end
