# Cache for mruby class references
module MrbClassCache
  @@cache = {} of String => MrbClass

  def self.register(crystal_class : Class, mrb_class : MrbClass)
    @@cache[crystal_class.name] = mrb_class
  end

  def self.get(crystal_class : Class)
    if @@cache[crystal_class.name]?
      return @@cache[crystal_class.name]
    else
      raise "Uncached class: #{crystal_class}"
    end
  end
end
