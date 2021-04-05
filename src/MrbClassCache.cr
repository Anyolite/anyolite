# Cache for mruby class and module references
module MrbClassCache
  @@cache = {} of String => Anyolite::RbClass | Anyolite::RbModule

  def self.register(crystal_class : Class, mrb_class : Anyolite::RbClass)
    @@cache[crystal_class.name] = mrb_class
  end

  def self.register(crystal_module : Class, mrb_module : Anyolite::RbModule)
    @@cache[crystal_module.name] = mrb_module
  end

  def self.get(n : Nil)
    nil
  end

  def self.get(ruby_module : Anyolite::RbModule)
    ruby_module
  end

  def self.get(crystal_class : Class)
    if @@cache[crystal_class.name]?
      return @@cache[crystal_class.name]
    else
      raise "Uncached class or module: #{crystal_class}"
    end
  end
end
