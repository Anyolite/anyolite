# Cache for mruby class references
module MrbModuleCache
  @@cache = {} of String => MrbModule

  def self.register(crystal_module : Class, mrb_module : MrbModule)
    @@cache[crystal_module.name] = mrb_module
  end

  def self.get(n : Nil)
    nil
  end

  def self.get(ruby_module : MrbModule)
    ruby_module
  end

  def self.get(crystal_module : Class)
    if @@cache[crystal_module.name]?
      return @@cache[crystal_module.name]
    else
      raise "Uncached class: #{crystal_module}"
    end
  end
end
