# This is a very simple approach to generate artificial references to the wrapped objects
# Therefore, the GC won't delete the wrapped objects until necessary
# Note that this is currently one-directional, so Mruby might still delete Crystal objects generated from Crystal itself

module MrbRefTable
  @@content = {} of UInt64 => Void*

  def self.get(identification)
    return @@content[identification]
  end

  def self.add(identification, value)
    @@content[identification] = value
  end

  def self.delete(identification)
    @@content.delete(identification)
    nil
  end
end